import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsMajor: XCTestCase {
  @MainActor
  func testMajorHappiestPath() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmMinorDevice)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- over 18
      $0.screen = .onboarding(.major(.explainHarderButPossible))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.askSelfOrOtherIsOnboarding))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.major(.askIfOtherIsParent))
      $0.onboarding.majorOnboarder = .other
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }
  }

  @MainActor
  func testMajorSelfPath1() async throws {
    let store = store(starting: .onboarding(.major(.askSelfOrOtherIsOnboarding)))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.onboarding.majorOnboarder = .self
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // first they click "what's an apple family" and see the sheet
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.major(.explainAppleFamily))
    }

    // dismiss the sheet (by button)
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // show the sheet again, so we can test the dismiss action
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.major(.explainAppleFamily))
    }

    // dismiss the sheet (by dismiss gesture)
    await store.send(.interactive(.sheetDismissed)) {
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // now they click that they could be in an apple family
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
    }

    // they click "is there another way?" from easy fix account screen
    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.major(.askIfOwnsMac))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.harderButPossible)))
      $0.onboarding.ownsMac = true
    }
  }

  @MainActor
  func testMajorSelfNoAppleFamilyStraightToSupervision() async throws {
    let store = store(starting: .onboarding(.major(.askSelfOrOtherIsOnboarding)))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.onboarding.majorOnboarder = .self
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.harderButPossible)))
    }
  }

  @MainActor
  func testMajorNoMacSetsState() async throws {
    let store = store(starting: .onboarding(.major(.askIfOwnsMac)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.harderButPossible)))
      $0.onboarding.ownsMac = false
    }
  }

  // TODO: superios re-enable after flow stabilizes
  // The supervision flow has been completely restructured with new states.
  // These tests will be rewritten in Task 21 after all iOS tasks complete.

  @MainActor
  func testSupervisionSetupFlow() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.harderButPossible))),
      onboarding: .init(majorOnboarder: .other, ownsMac: true),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.explainSupervisionConcept)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.explainSupervisionOptions)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.offerWorkaround)))
    }
  }

  @MainActor
  func testSupervisionWorkaroundPath() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.explainSiblingWorkaround))),
      onboarding: .init(majorOnboarder: .self, ownsMac: true),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.siblingWorkaroundInstructions)))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }
  }

  @MainActor
  func testSupervisionChooseGertrudeTool() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.setup(.chooseSupervisionPath))),
      onboarding: .init(majorOnboarder: .self, ownsMac: false),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadSupervisionCode = { nil }
      $0.api.createSupervisionCode = { .init(code: 123_123, expiresAt: .reference) }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.askHasProtector)))
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
  func testSupervisionOtherNotParentOrGuardian() async throws {
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.major(.askIfOtherIsParent)),
      onboarding: .init(majorOnboarder: .other, ownsMac: nil),
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.major(.askIfOwnsMac))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.setup(.harderButPossible)))
      $0.onboarding.ownsMac = false
    }
  }
}
