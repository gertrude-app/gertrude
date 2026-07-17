import ComposableArchitecture
import Core
import Filter
import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

/// End-to-end filter-suspension lifecycle across websocket, XPC, filter state,
/// flow verdicts, expiry, and app cleanup.
final class SuspensionScenarioTests: XCTestCase {
  @MainActor
  func testFilterSuspensionLifecycleEndToEnd() async throws {
    _ = try await self.runScenario()
  }

  @MainActor
  func testScenarioIsDeterministic() async throws {
    let first = try await self.runScenario()
    let second = try await self.runScenario()
    expect(second.map(\.description).joined(separator: "\n"))
      .toEqual(first.map(\.description).joined(separator: "\n"))
  }

  @MainActor
  private func runScenario() async throws -> [TraceEvent] {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedAppDisk(uid: child, user: .mock)

    // boot: the system starts the enabled filter extension (no user logged in
    // yet); with no persisted rules and no alive macapp, protected-user
    // traffic fails closed
    await world.bootFilterExtension()
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.drop)

    // user logs in: macapp launches, establishes XPC, checks in, and
    // delivers the child's rules to the filter
    let checkIn = LockIsolated(CheckIn_v2.Output.sim(keychains: [.gitHubOnly]))
    let app = await world.launchApp(uid: child, checkInOutput: checkIn)
    expect(world.connectedXpcUids).toEqual([child])
    expect(world.filterProcess!.state.userKeychains[child]?.numKeys).toEqual(1)

    // rules live: allowed domain flows, everything else drops
    await expect(world.browse("https://github.com", as: child)).toEqual(.allow)
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.drop)

    // and the filter persisted them durably (its own root defaults domain)
    expect(world.filterPersistedState(numKeysFor: child)).toEqual(1)

    // parent grants a 10-minute suspension, decision pushed over websocket
    await world.websocketPush(to: child, .filterSuspensionRequestDecided_v2(
      id: .deadbeef,
      decision: .accepted(duration: 600, extraMonitoring: nil),
      comment: nil,
    ))

    // app recorded the expiration, filter holds the live suspension
    expect(app.state.filter.currentSuspensionExpiration)
      .toEqual(world.currentDate.value + 600)
    expect(world.filterProcess!.state.suspensions[child] != nil).toBeTrue()
    expect(world.trace.value.contains(
      .notification(child, title: "🟠 Temporarily disabling filter"),
    )).toBeTrue()

    // suspended: previously blocked traffic flows
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.allow)

    // 9 minutes pass; app heartbeats keep the filter's macapp-alive window
    // fresh, so the suspension stays honored
    await world.advanceTime(seconds: 540)
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.allow)

    // suspension expires: filter timer fires, suspension cleared, app
    // notified over XPC and cleans up its own projection
    await world.advanceTime(seconds: 60)
    expect(world.filterProcess!.state.suspensions[child]).toBeNil()
    expect(app.state.filter.currentSuspensionExpiration).toBeNil()
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.drop)

    // app announced filter state and warned about browsers quitting
    expect(world.trace.value.contains(
      .notification(child, title: "⚠️ Web browsers quitting soon!"),
    )).toBeTrue()

    // after the 60s grace period, browsers quit
    expect(world.trace.value.contains(.browsersQuit(child))).toBeFalse()
    await world.advanceTime(seconds: 60)
    expect(world.trace.value.contains(.browsersQuit(child))).toBeTrue()

    await world.shutdown()
    return world.trace.value
  }

  @MainActor
  func testPerUserXpcConnectionsDoNotStealEachOther() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    let buddy: uid_t = 503
    try world.seedAppDisk(uid: child, user: .mock)
    try world.seedAppDisk(uid: buddy, user: .mock)
    await world.bootFilterExtension()

    let childCheckIn = LockIsolated(CheckIn_v2.Output.sim(keychains: [.gitHubOnly]))
    let buddyOutput: CheckIn_v2.Output = {
      var output = CheckIn_v2.Output.sim(keychains: [.gitLabOnly])
      output.userData.filteringDisabled = false
      return output
    }()
    let buddyCheckIn = LockIsolated(buddyOutput)

    let childApp = await world.launchApp(uid: child, checkInOutput: childCheckIn)
    _ = await world.launchApp(uid: buddy, checkInOutput: buddyCheckIn)

    expect(world.connectedXpcUids).toEqual([child, buddy])
    expect(world.filterProcess!.state.userKeychains[child]?.numKeys).toEqual(1)
    expect(world.filterProcess!.state.userKeychains[buddy]?.numKeys).toEqual(1)

    await world.websocketPush(to: child, .filterSuspensionRequestDecided_v2(
      id: .deadbeef,
      decision: .accepted(duration: 300, extraMonitoring: nil),
      comment: nil,
    ))

    expect(childApp.state.filter.currentSuspensionExpiration)
      .toEqual(world.currentDate.value + 300)
    expect(world.filterProcess!.state.suspensions[child] != nil).toBeTrue()
  }
}

// fixtures

extension RuleKeychain {
  static let gitHubOnly = RuleKeychain(
    id: .ones,
    keys: [.init(
      id: .twos,
      key: .domain(domain: .init(string: "github.com"), scope: .unrestricted),
    )],
  )
}

extension CheckIn_v2.Output {
  static func sim(keychains: [RuleKeychain]) -> Self {
    .init(
      adminAccountStatus: .active,
      appManifest: .init(),
      keychains: keychains,
      latestRelease: .init(semver: VirtualMac.appVersion),
      updateReleaseChannel: .stable,
      userData: .mock,
      browsers: [.bundleId("com.google.Chrome"), .name("Safari")],
      trustedTime: 0,
    )
  }
}
