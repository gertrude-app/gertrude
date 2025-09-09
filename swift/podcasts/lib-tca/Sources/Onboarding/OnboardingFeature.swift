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
    case primaryBtnTapped
    case secondaryBtnTapped
    case finished(Int)
    case setShowingPasscodeSheet(Bool)
    case passcodeSet(Int)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch (state.screen, action) {
      case (.hiThere, .primaryBtnTapped):
        state.screen = .areYouTheParent
        return .none
      case (.areYouTheParent, .primaryBtnTapped):
        state.screen = .explainSetPasscode
        return .none
      case (.areYouTheParent, .secondaryBtnTapped):
        state.screen = .parentRequired
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
      case (_, .passcodeSet(let passcode)):
        state.screen = .passcodeSet(passcode)
        state.showingPasscodeSheet = false
        return .none
      case (.passcodeSet, .finished):
        return .none // handled by root reducer
      default:
        #if DEBUG
          fatalError("Unhandled state-action pair: \(state.screen) - \(action)")
        #else
          return .none
        #endif
      }
    }
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
