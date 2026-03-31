import ComposableArchitecture
import GertieIOS
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
      $0.api.checkSupervisionFlowStatus = { @Sendable _ in .pending }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
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
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
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
      $0.api.checkSupervisionFlowStatus = { @Sendable _ in .expired }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
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
      $0.api.checkSupervisionFlowStatus = { @Sendable _ in .notFound }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
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
      $0.api.checkSupervisionFlowStatus = { @Sendable _ in .claimed(.mock) }
      $0.api.setAccountConnection = { @Sendable _ in accountSet.setValue(true) }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
      $0.sharedStorage.clearPendingSupervisionCode = { fatalError("not cleared") }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.codeClaimedNotSupervised)))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.codeClaimedNotSupervised)))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
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
      $0.api.checkSupervisionFlowStatus = { @Sendable _ in .missingProfile(.mock) }
      $0.api.setAccountConnection = { @Sendable _ in accountSet.setValue(true) }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
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
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
    }
    expect(accountSet.value).toEqual(true)
    expect(connSaved.value).toEqual(true)
  }

  @MainActor
  func testSupervisionReboot_networkError_showsErrorThenRetrySucceeds() async throws {
    let code = 123_456
    let attemptCount = LockIsolated(0)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.continuousClock = ImmediateClock()
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
      $0.sharedStorage.loadPendingSupervisionCode = {
        .init(code: code, expiresAt: .reference)
      }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.api.checkSupervisionFlowStatus = { @Sendable _ in
        let attempt = attemptCount.withValue { val in val += 1
          return val
        }
        if attempt <= 4 {
          throw URLError(.notConnectedToInternet)
        }
        return .pending
      }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.networkError)))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.networkError)))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "Try again"))) {
      $0.screen = .launching
    }

    await store.receive(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast)))
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.codeNotClaimed(code: code))))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.codeNotClaimed(code: code))))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true))))
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
      $0.api.checkSupervisionFlowStatus = { @Sendable _ in .complete(.mock) }
      $0.api.setAccountConnection = { @Sendable _ in accountSet.setValue(true) }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
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
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
    }
  }

  @MainActor
  func testProfileRemovedRecovery_supervisedUser_showsRecoveryScreen() async throws {
    let accountSet = LockIsolated(false)
    let connSaved = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in [BlockGroup.gifs.legacyUUID] }
      $0.sharedStorage.loadAccountConnection = { .mock }
      $0.sharedStorage.saveAccountConnection = { @Sendable _ in connSaved.setValue(true) }
      $0.api.setAccountConnection = { @Sendable _ in accountSet.setValue(true) }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setProfileRecovery)) {
      $0.onboarding.isProfileRecovery = true
    }
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.profileRemovedRecovery)))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.profileRemovedRecovery)))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
    }
    await store
      .receive(.programmatic(.receivedDisabledBlockGroupIds([BlockGroup.gifs.legacyUUID]))) {
        $0.disabledBlockGroupIds = [BlockGroup.gifs.legacyUUID]
      }
    expect(accountSet.value).toEqual(true)
    expect(connSaved.value).toEqual(true)
  }

  @MainActor
  func testProfileRemovedRecovery_nonSupervisedUser_showsHiThere() async throws {
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in [BlockGroup.gifs.legacyUUID] }
      $0.sharedStorage.loadAccountConnection = { .mock { $0.supervised = nil } }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: true) }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
    }
    await store
      .receive(.programmatic(.receivedDisabledBlockGroupIds([BlockGroup.gifs.legacyUUID]))) {
        $0.disabledBlockGroupIds = [BlockGroup.gifs.legacyUUID]
      }
  }

  @MainActor
  func testProfileRecovery_reinstallRoutesToProfileInstall() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.profileRemovedRecovery))),
      onboarding: .init(),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "Reinstall profile"))) {
      $0.screen = .onboarding(.supervision(.resume(.promptInstallProfile)))
    }
  }

  @MainActor
  func testProfileRecovery_afterInstall_goesToRunning() async throws {
    var state = IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.profileInstalled))),
    )
    state.onboarding.isProfileRecovery = true
    let store = TestStore(initialState: state) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "Next"))) {
      $0.onboarding.isProfileRecovery = false
      $0.screen = .running(state: .connected)
    }
  }

  @MainActor
  func testLaunchState_freshInstall_returnsOnboardingNeeded() async throws {
    let state = await withDependencies {
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.sharedStorage.loadPendingSupervisionCode = { @Sendable in nil }
    } operation: {
      await IOSReducer.Deps().launchState()
    }
    guard case .onboardingNeeded = state else {
      XCTFail("expected .onboardingNeeded, got \(state)")
      return
    }
  }

  @MainActor
  func testLaunchState_emptyGroupIds_filterNotRunning_returnsFilterNoLongerRunning() async throws {
    let state = await withDependencies {
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage
        .loadDisabledBlockGroupIds = { @Sendable in
          []
        } // <-- buggy 1.8.0 migration wrote this for fresh installs
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.sharedStorage.loadPendingSupervisionCode = { @Sendable in nil }
    } operation: {
      await IOSReducer.Deps().launchState()
    }
    guard case .filterNoLongerRunning = state else {
      XCTFail("expected .filterNoLongerRunning, got \(state)")
      return
    }
  }

  @MainActor
  func testLaunchState_connectedFilterRunning_returnsRunningConnected() async throws {
    let state = await withDependencies {
      $0.systemExtension.filterRunning = { true }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in [BlockGroup.gifs.legacyUUID] }
      $0.sharedStorage.loadAccountConnection = { @Sendable in .mock }
      $0.sharedStorage.loadPendingSupervisionCode = { @Sendable in nil }
    } operation: {
      await IOSReducer.Deps().launchState()
    }
    guard case .running(.connected) = state else {
      XCTFail("expected .running(.connected), got \(state)")
      return
    }
  }

  @MainActor
  func testLaunchState_unconnectedFilterRunning_returnsRunningUnconnected() async throws {
    let state = await withDependencies {
      $0.systemExtension.filterRunning = { true }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in [BlockGroup.gifs.legacyUUID] }
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.sharedStorage.loadPendingSupervisionCode = { @Sendable in nil }
    } operation: {
      await IOSReducer.Deps().launchState()
    }
    guard case .running(.unconnected) = state else {
      XCTFail("expected .running(.unconnected), got \(state)")
      return
    }
  }

  @MainActor
  func testLaunchState_filterRunningNoGroups_returnsConfiguratorFirstLaunch() async throws {
    let state = await withDependencies {
      $0.systemExtension.filterRunning = { true }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.sharedStorage.loadPendingSupervisionCode = { @Sendable in nil }
    } operation: {
      await IOSReducer.Deps().launchState()
    }
    guard case .configuratorSupervisionFirstLaunch = state else {
      XCTFail("expected .configuratorSupervisionFirstLaunch, got \(state)")
      return
    }
  }

  @MainActor
  func testFilterNoLongerRunning_fetchesConnectAccountFeatureFlag() async throws {
    let flagFetched = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in [BlockGroup.gifs.legacyUUID] }
      $0.sharedStorage.loadAccountConnection = { .mock { $0.supervised = nil } }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.logEvent = { @Sendable _, _ in }
      $0.sharedStorage.migrateLegacyData = { @Sendable in false }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.api.connectAccountFeatureFlag = {
        flagFetched.setValue(true)
        return .init(isEnabled: true)
      }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: true)))) {
      $0.onboarding.connectFeature = .init(isEnabled: true)
    }
    await store
      .receive(.programmatic(.receivedDisabledBlockGroupIds([BlockGroup.gifs.legacyUUID]))) {
        $0.disabledBlockGroupIds = [BlockGroup.gifs.legacyUUID]
      }
    XCTAssertTrue(flagFetched.value)
  }
}

extension CreateSupervisionClaimCode.Output {
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
