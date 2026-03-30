import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsMajor: XCTestCase {
  @MainActor
  func testOver18SupervisionHappyPath() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmMinorDevice)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- over 18
      $0.screen = .onboarding(.supervision(.setup(.adultNeedsSupervision)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.whatIsSupervisedMode)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.supervisedDeviceReassurance)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.explainSupervision)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.costAndBranchPoint)))
    }
  }

  @MainActor
  func testSupervisionSetupFlow() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.adultNeedsSupervision))),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.whatIsSupervisedMode)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.supervisedDeviceReassurance)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.explainSupervision)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.costAndBranchPoint)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
    }
  }

  @MainActor
  func testSupervisionBirthdayAlternativePath() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.freeAlternativesHub))),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.birthdayAlternativeExplain)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.birthdayAlternativeCons)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.birthdayAlternativeInstructions)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.accountNowUnder18)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
    }
  }

  @MainActor
  func testSupervisionSiblingAlternativePath() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.freeAlternativesHub))),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.siblingAlternativeExplain)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.siblingAlternativeCons)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.siblingAlternativeInstructions)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.accountNowUnder18)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
    }
  }

  @MainActor
  func testSupervisionAppleConfiguratorPath() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.freeAlternativesHub))),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.appleConfiguratorExplain)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.appleConfiguratorCons(step: 1))))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.appleConfiguratorCons(step: 2))))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.appleConfiguratorCons(step: 3))))
    }
  }

  @MainActor
  func testSupervisionContinueWithGertrude() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.costAndBranchPoint))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
      $0.sharedStorage.savePendingSupervisionCode = { _ in }
      $0.api.createSupervisionClaimCode = { .init(code: 123_123, expiresAt: .reference) }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store
      .receive(.programmatic(.setScreen(.onboarding(.supervision(.setup(.generateSetupCode())))))) {
        $0.screen = .onboarding(.supervision(.setup(.generateSetupCode())))
      }

    await store
      .receive(.programmatic(.supervisionCodeGenerated(code: 123_123))) {
        $0.screen = .onboarding(.supervision(.setup(.instructionsForProtector(code: 123_123))))
      }
  }

  @MainActor
  func testSupervisionGertrudeFromHub() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.freeAlternativesHub))),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.quaternary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
    }
  }

  @MainActor
  func testSelfManagementPlaceholder_goesToHiThere() async throws {
    let store = store(starting: .onboarding(.supervision(.setup(.explainNeedSomeoneElse))))
    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.selfManagementPlaceholder)))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
  }

  @MainActor
  func testGenerateSetupCode_retry_succeeds() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let saved = LockIsolated(false)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.generateSetupCode(didError: true)))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.api.createSupervisionClaimCode = { .init(code: code, expiresAt: .reference) }
      $0.sharedStorage.savePendingSupervisionCode = { _ in saved.setValue(true) }
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(.supervisionCodeGenerated(code: code))) {
      $0.screen = .onboarding(.supervision(.setup(.instructionsForProtector(code: code))))
    }
    expect(saved.value).toEqual(true)
  }

  @MainActor
  func testGenerateSetupCode_apiError_showsError() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.explainNeedSomeoneElse))),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
      $0.api.createSupervisionClaimCode = { throw NSError(domain: "test", code: 1) }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(
      .setScreen(.onboarding(.supervision(.setup(.generateSetupCode())))),
    )) {
      $0.screen = .onboarding(.supervision(.setup(.generateSetupCode())))
    }
    await store.receive(.programmatic(.supervisionCodeGenerationFailed)) {
      $0.screen = .onboarding(.supervision(.setup(.generateSetupCode(didError: true))))
    }
  }
}
