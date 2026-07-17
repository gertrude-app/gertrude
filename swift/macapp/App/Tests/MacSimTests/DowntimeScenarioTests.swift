import ComposableArchitecture
import Core
import Filter
import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

/// Downtime enforcement survives provider relaunch through persisted filter
/// state, without waiting for the next app rules delivery.
final class DowntimeScenarioTests: XCTestCase {
  @MainActor
  func testDowntimeSurvivesFilterCrashRespawn() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedAppDisk(uid: child, user: .mock)
    await world.bootFilterExtension()

    // downtime window opens 2 sim-minutes from now
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let window = PlainTimeWindow(
      start: .from(world.currentDate.value + 120, in: calendar),
      end: .from(world.currentDate.value + 120 + 3600, in: calendar),
    )
    let output: CheckIn_v2.Output = {
      var output = CheckIn_v2.Output.sim(keychains: [.gitHubOnly])
      output.userData.downtime = window
      output.userData.filteringDisabled = false
      return output
    }()
    let checkIn = LockIsolated(output)

    // app launches, checks in, delivers rules + downtime to the filter
    _ = await world.launchApp(uid: child, checkInOutput: checkIn)
    await expect(world.browse("https://github.com", as: child)).toEqual(.allow)

    // downtime begins: even the allowlisted host is blocked
    await world.advanceTime(seconds: 180)
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)

    // relaunch reloads durable downtime before the next rules delivery
    await world.crashAndRecoverFilterProvider()
    await world.advanceTime(seconds: 360)

    // still inside the downtime window
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)
  }
}
