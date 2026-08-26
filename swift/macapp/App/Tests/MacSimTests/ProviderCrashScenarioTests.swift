import ComposableArchitecture
import Core
import Filter
import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

/// Provider lifecycle scenarios for liveness gating, provider absence, verdict
/// finality, and durable-state reload.
final class ProviderCrashScenarioTests: XCTestCase {
  @MainActor
  func testProtectedTrafficFailsClosedUntilAppIsAlive() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedFilterDisk(userKeychains: [child: [.gitHubOnly]])
    await world.bootFilterExtension()

    // protected users fail closed until the app is marked alive
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)

    // liveness restores normal rule evaluation
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

    // provider absent: traffic is outside filter enforcement
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

    // connection opened while the provider is absent is allowed
    world.killFilterProviderProcess()
    let leaked = await world.openConnection(to: "youtube.com", as: child)
    expect(leaked).not.toBeNil()
    expect(world.connectionCarriesData(leaked!)).toBeTrue()

    // new flows are rechecked after relaunch; existing connections are not
    await world.bootFilterExtension()
    await world.deliverAppAlive(child)
    let freshBlocked = await world.openConnection(to: "reddit.com", as: child)
    expect(freshBlocked).toBeNil()
    expect(world.connectionCarriesData(leaked!)).toBeTrue() // leak survives respawn

    // reboot clears open connections
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

    // relaunch reloads rules, but in-memory liveness is gone
    await world.crashAndRecoverFilterProvider()
    expect(world.filterProcess!.state.userKeychains[child]?.numKeys).toEqual(1)
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)

    await world.deliverAppAlive(child)
    await expect(world.browse("https://github.com", as: child)).toEqual(.allow)
    await expect(world.browse("https://youtube.com", as: child)).toEqual(.drop)
  }
}
