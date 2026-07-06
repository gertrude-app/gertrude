import ComposableArchitecture
import Core
import Filter
import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

/// Scenarios encoding the 2026-07-06 VM witnesses for the filter provider's
/// crash/reboot lifecycle: app-liveness gating / AWOL fail-closed (the filter's
/// real `Decision+Flow` code, exercised here), fail-open while the provider is
/// absent (OS RULE M3), flow-verdict finality preserving connections opened
/// during that window (OS RULE M4), and crash-recovery reloading rules from
/// disk (OS RULE M1). See `swift/macapp/conformance/vm-witness-findings.md`.
final class ProviderCrashScenarioTests: XCTestCase {
  @MainActor
  func testProtectedTrafficFailsClosedUntilAppIsAlive() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedFilterDisk(userKeychains: [child: [.gitHubOnly]])
    await world.bootFilterExtension()

    // provider up + rules loaded, but no app has said "alive" yet: the filter
    // fails CLOSED for the protected user — even the allowlisted host is dropped
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)

    // app announces itself alive → normal rule evaluation resumes
    await world.deliverAppAlive(child)
    await expect(world.browse("https://github.com", as: child)).toEqual(.allow)
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.drop)
  }

  @MainActor
  func testTrafficFailsOpenWhileProviderAbsent() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedFilterDisk(userKeychains: [child: [.gitHubOnly]])
    await world.bootFilterExtension()
    await world.deliverAppAlive(child)

    // provider up: an off-list host is blocked
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.drop)

    // provider crashes — until it respawns, ALL traffic flows (OS RULE M3)
    world.killFilterProviderProcess()
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.allow)
  }

  @MainActor
  func testConnectionOpenedDuringFailOpenSurvivesRespawn() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedFilterDisk(userKeychains: [child: [.gitHubOnly]])
    await world.bootFilterExtension()
    await world.deliverAppAlive(child)

    // off-list connection blocked while filtering normally
    let blockedBefore = await world.openConnection(to: "youtube.com", as: child)
    expect(blockedBefore).toBeNil()

    // provider crashes; a connection opened during the gap fails OPEN
    world.killFilterProviderProcess()
    let leaked = await world.openConnection(to: "youtube.com", as: child)
    expect(leaked).not.toBeNil()
    expect(world.connectionCarriesData(leaked!)).toBeTrue()

    // OS respawns the provider (reloads rules), app re-announces alive: NEW
    // off-list flows are blocked again, but the leaked connection keeps carrying
    // data (OS RULE M4)
    await world.bootFilterExtension()
    await world.deliverAppAlive(child)
    let freshBlocked = await world.openConnection(to: "reddit.com", as: child)
    expect(freshBlocked).toBeNil() // new flow re-evaluated → dropped
    expect(world.connectionCarriesData(leaked!)).toBeTrue() // leak survives respawn

    // a full reboot clears the leak (OS RULE M1/M4)
    await world.rebootDevice()
    expect(world.connectionCarriesData(leaked!)).toBeFalse()
  }

  @MainActor
  func testCrashRecoveryReloadsRulesAndLosesLivenessUntilResync() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedFilterDisk(userKeychains: [child: [.gitHubOnly]])
    await world.bootFilterExtension()
    await world.deliverAppAlive(child)
    expect(world.filterProcess!.state.userKeychains[child]?.numKeys).toEqual(1)
    await expect(world.browse("https://github.com", as: child)).toEqual(.allow)

    // crash + OS respawn: the fresh process reloads persisted rules from disk,
    // but its in-memory liveness is lost — so until the app re-announces alive,
    // even the allowlisted host is AWOL-dropped (device: the respawn's
    // receiveAlive(for: 502) is what closes this window)
    await world.crashAndRecoverFilterProvider()
    expect(world.filterProcess!.state.userKeychains[child]?.numKeys).toEqual(1)
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)

    await world.deliverAppAlive(child)
    await expect(world.browse("https://github.com", as: child)).toEqual(.allow)
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.drop)
  }
}
