import ComposableArchitecture
import IOSRoute
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsResume: XCTestCase {
  @MainActor
  func testCodeNotClaimed_showsInstructionsThenWaiting() async throws {
    let store = store(starting: .onboarding(.supervision(.resume(.codeNotClaimed(code: 123)))))
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.instructionsForProtector(code: 123))))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.waitingForSupervision(code: 123))))
    }
  }

  @MainActor
  func testClaimedNotSupervised_yesSupervised_reportsAndPromptsProfile() async throws {
    let reported = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.codeClaimedNotSupervised()))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.api.selfReportSupervision = { @Sendable isSupervised in
        expect(isSupervised).toEqual(true)
        reported.setValue(true)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store
      .receive(
        .programmatic(.setScreen(.onboarding(.supervision(.resume(.promptInstallProfile))))),
      ) {
        $0.screen = .onboarding(.supervision(.resume(.promptInstallProfile)))
      }
    expect(reported.value).toEqual(true)
  }

  @MainActor
  func testClaimedNotSupervised_yesSupervised_requiresSubscriptionOn402() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.codeClaimedNotSupervised()))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.api.selfReportSupervision = { @Sendable _ in
        throw PqlError(id: "test", requestId: "test", type: .paymentRequired, debugMessage: "test")
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store
      .receive(
        .programmatic(.setScreen(.onboarding(.supervision(.resume(.requiresSubscription))))),
      ) {
        $0.screen = .onboarding(.supervision(.resume(.requiresSubscription)))
      }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.codeClaimedNotSupervised())))
    }
  }

  @MainActor
  func testClaimedNotSupervised_doesNotRequireSubscriptionOnOtherErrors() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.codeClaimedNotSupervised()))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.api.selfReportSupervision = { @Sendable _ in
        throw URLError(.notConnectedToInternet)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
  }

  @MainActor
  func testClaimedNotSupervised_notSupervised_reportsAndRetries() async throws {
    let reported = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.codeClaimedNotSupervised()))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.api.selfReportSupervision = { @Sendable isSupervised in
        expect(isSupervised).toEqual(false)
        reported.setValue(true)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.retrySupervision)))
    }
    expect(reported.value).toEqual(true)
  }

  @MainActor
  func testClaimedNotSupervised_foreground_setsRegainedFocus() async throws {
    let store = store(
      starting: .onboarding(.supervision(.resume(.codeClaimedNotSupervised()))),
    )
    await store.send(.programmatic(.appDidEnterForeground)) {
      $0.screen = .onboarding(.supervision(.resume(.codeClaimedNotSupervised(regainedFocus: true))))
    }
  }

  @MainActor
  func testRetrySupervision_withCode_goesToInstructions() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.retrySupervision))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadPendingSupervisionCode = {
        .init(code: 123, expiresAt: .reference)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.instructionsForProtector(code: 123))))
    }
  }

  @MainActor
  func testRetrySupervision_noCode_fallsBackToExplain() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.retrySupervision))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
    }
  }

  @MainActor
  func testProfileInstallFlow_happyPath() async throws {
    let deviceId = UUID()
    let codeCleaned = LockIsolated(false)
    let setupCompleted = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.promptInstallProfile))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadAccountConnection = { @Sendable in .mock {
        $0.deviceId = deviceId
        $0.childName = "Franny"
      } }
      $0.sharedStorage.clearPendingSupervisionCode = { codeCleaned.setValue(true) }
      $0.systemExtension.filterRunning = { true }
      $0.continuousClock = ImmediateClock()
      $0.api.markSupervisionProfileInstalled = { @Sendable in setupCompleted.setValue(true) }
    }

    let profileUrl = URL(string: "https://api.gertrude.app/ios-profile/\(deviceId)")!

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.explainProfileDownload)))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.resume(.installingProfile(profileUrl: profileUrl))))),
    )) {
      $0.screen = .onboarding(.supervision(.resume(.installingProfile(profileUrl: profileUrl))))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.profileDownloaded)))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.profileNotRemovableWarning)))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.explainProfileInstall())))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: false))))
    }
    await store.receive(.programmatic(.filterVerified)) {
      $0.screen = .onboarding(.supervision(.resume(.profileInstalled)))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.websiteWarning(childName: "Franny"))))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.promptClearCache)))
    }
    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.happyPath(.requestAppStoreRating))
    }
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }
    expect(codeCleaned.value).toEqual(true)
    expect(setupCompleted.value).toEqual(true)
  }

  @MainActor
  func testProfileInstallFlow_verificationFails_retrySucceeds() async throws {
    let filterRunning = LockIsolated(true)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.explainProfileInstall()))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.systemExtension.filterRunning = { filterRunning.value }
      $0.api.markSupervisionProfileInstalled = { @Sendable in }
    }

    await store.send(.programmatic(.appDidEnterForeground)) {
      $0.screen = .onboarding(.supervision(.resume(.explainProfileInstall(regainedFocus: true))))
    }

    filterRunning.setValue(false) // <-- simulate filter not running on first try
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: false))))
    }
    await store.receive(.programmatic(.filterVerificationFailed)) {
      $0.screen = .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: true))))
    }

    filterRunning.setValue(true) // <-- now it's running
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: false))))
    }
    await store.receive(.programmatic(.filterVerified)) {
      $0.screen = .onboarding(.supervision(.resume(.profileInstalled)))
    }
  }

  @MainActor
  func testSupervisionCacheClearCompletion_clearsCode() async throws {
    let codeCleaned = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.promptClearCache))),
      onboarding: .init(),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.clearPendingSupervisionCode = { codeCleaned.setValue(true) }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.onboarding.clearCache = .init(context: .onboarding)
    }

    await store.send(.interactive(.onboardingClearCache(.completeBtnTapped))) {
      $0.onboarding.clearCache = nil
      $0.screen = .onboarding(.happyPath(.requestAppStoreRating))
    }
    expect(codeCleaned.value).toEqual(true)
  }
}
