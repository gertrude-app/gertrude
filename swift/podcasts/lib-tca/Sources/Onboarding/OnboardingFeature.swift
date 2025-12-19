import ComposableArchitecture
import SwiftUI

@Reducer
struct OnboardingFeature {
  @ObservableState
  struct State: Equatable {
    var screen: OnboardingScreen = .hiThere
    var showingPasscodeSheet: Bool = false
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case shouldNotBeOnboarding
    }

    case primaryBtnTapped
    case secondaryBtnTapped
    case finished(Int)
    case setShowingPasscodeSheet(Bool)
    case passcodeSet(Int)
    case passcodeConfirmFailed
    case delegate(DelegateAction)
  }

  @Dependency(\.db) var database
  @Dependency(\.keychain) var keychain
  @Dependency(\.haptics) var haptics

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch (state.screen, action) {
      case (.hiThere, .primaryBtnTapped):
        state.screen = .areYouTheParent
        return self.shouldNotBeOnboarding() ? .send(.delegate(.shouldNotBeOnboarding)) : .none
      case (.areYouTheParent, .primaryBtnTapped):
        state.screen = .explainSetPasscode
        return .none
      case (.areYouTheParent, .secondaryBtnTapped):
        state.screen = .parentRequired
        log(.info("4936b4ff"), "onboarding, not parent")
        return .none
      case (.parentRequired, .primaryBtnTapped):
        state.screen = .hiThere
        return .none
      case (.explainSetPasscode, .primaryBtnTapped):
        state.screen = .strongPasscode
        return .none
      case (.strongPasscode, .primaryBtnTapped):
        state.showingPasscodeSheet = true
        return .none
      case (_, .setShowingPasscodeSheet(false)):
        state.showingPasscodeSheet = false
        return .none
      case (_, .passcodeConfirmFailed):
        return .run { _ in
          await self.haptics.notification(.error)
        }
      case (_, .passcodeSet(let passcode)):
        state.screen = .passcodeSet(passcode)
        state.showingPasscodeSheet = false
        return .run { _ in
          await self.haptics.notification(.success)
        }
      case (.passcodeSet, .finished):
        return .none // handled by root reducer
      case (_, .delegate):
        return .none
      default:
        #if DEBUG
          fatalError("Unhandled state-action pair: \(state.screen) - \(action)")
        #else
          return .none
        #endif
      }
    }
  }

  func shouldNotBeOnboarding() -> Bool {
    if self.keychain.loadPincode() != nil {
      return true
    }
    let previouslyCompleted = self.database.tryRead { db in
      try Record.find(id: .onboardingFinished).fetchOne(db) != nil
    }
    if previouslyCompleted == true {
      return true
    }
    let numShows = self.database.tryRead { db in
      try Show.count().fetchOne(db)
    }
    if (numShows ?? 0) > 0 {
      return true
    }
    return false
  }
}

enum OnboardingScreen: Equatable {
  case hiThere
  case areYouTheParent
  case parentRequired
  case explainSetPasscode
  case strongPasscode
  case passcodeSet(Int)
}
