import ComposableArchitecture
import IOSRoute
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsLaunch: XCTestCase {
  @MainActor
  func testSupervisionReboot_pending_goesToCodeNotClaimed() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.api.checkSupervisionStatus = { @Sendable _ in .pending }
      $0.sharedStorage.loadPendingSupervisionCode = {
        .init(code: code, expiresAt: .reference)
      }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.codeNotClaimed(code: code))))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.codeNotClaimed(code: code))))
    }
  }

  @MainActor
  func testSupervisionReboot_expired_startsOver() async throws {
    let clearedCode = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { .mock }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.clearPendingSupervisionCode = { clearedCode.setValue(true) }
      $0.api.checkSupervisionStatus = { @Sendable _ in .expired }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
    expect(clearedCode.value).toEqual(true)
  }

  @MainActor
  func testSupervisionReboot_notFound_restarts() async throws {
    let clearedCode = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { .mock }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.clearPendingSupervisionCode = { clearedCode.setValue(true) }
      $0.api.checkSupervisionStatus = { @Sendable _ in .notFound }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
    expect(clearedCode.value).toEqual(true)
  }

  @MainActor
  func testSupervisionReboot_claimedNotSupervised() async throws {
    let accountSet = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { .mock }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.saveAccountConnection = { @Sendable _ in }
      $0.api.checkSupervisionStatus = { @Sendable _ in .claimed(.mock) }
      $0.api.setAccountConnection = { @Sendable _ in accountSet.setValue(true) }
      $0.sharedStorage.clearPendingSupervisionCode = { fatalError("not cleared") }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.codeClaimedNotSupervised())))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.codeClaimedNotSupervised())))
    }
    expect(accountSet.value).toEqual(true)
  }

  @MainActor
  func testSupervisionReboot_missingProfile_happyPath() async throws {
    let accountSet = LockIsolated(false)
    let connSaved = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { .mock }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.saveAccountConnection = { @Sendable _ in connSaved.setValue(true) }
      $0.api.checkSupervisionStatus = { @Sendable _ in .missingProfile(.mock) }
      $0.api.setAccountConnection = { @Sendable _ in accountSet.setValue(true) }
      $0.sharedStorage.clearPendingSupervisionCode = { fatalError("not cleared") }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.promptInstallProfile)))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.promptInstallProfile)))
    }
    expect(accountSet.value).toEqual(true)
    expect(connSaved.value).toEqual(true)
  }

  @MainActor
  func testSupervisionReboot_complete_serverClientDisagreement() async throws {
    let accountSet = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { .mock }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.saveAccountConnection = { @Sendable _ in }
      $0.api.checkSupervisionStatus = { @Sendable _ in .complete(.mock) }
      $0.api.setAccountConnection = { @Sendable _ in accountSet.setValue(true) }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.promptInstallProfile)))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.promptInstallProfile)))
    }
  }
}

extension CreateSupervisionCode.Output {
  static var mock: Self {
    .init(code: Int.random(in: 100_000 ... 999_999), expiresAt: .reference)
  }
}

extension ChildIOSDeviceData_v2 {
  static var mock: Self { mock { _ in } }
  static func mock(_ config: (inout Self) -> Void) -> Self {
    var val = Self(
      childId: UUID(),
      token: UUID(),
      deviceId: UUID(),
      childName: "Test".random,
      supervised: .byGertrude(claimCode: Int.random(in: 100_000 ... 999_999)),
    )
    config(&val)
    return val
  }
}
