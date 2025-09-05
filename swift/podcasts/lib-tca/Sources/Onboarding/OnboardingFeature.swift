import ComposableArchitecture
import SwiftUI

@Reducer
struct OnboardingFeature {
  @ObservableState
  struct State: Equatable {
    var screen: OnboardingScreen = .hiThere
    var showingPinSheet: Bool = false
  }

  enum Action: Equatable {
    case primaryBtnTapped
    case secondaryBtnTapped
    case lastBtnTapped
    case setShowingPinSheet(Bool)
    case pinSet(Int)
  }

  @Dependency(\.passcode) var passcode

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch (state.screen, action) {
      case (.hiThere, .primaryBtnTapped):
        state.screen = .areYouTheParent
        return .none
      case (.areYouTheParent, .primaryBtnTapped):
        state.screen = .explainSetPin
        return .none
      case (.areYouTheParent, .secondaryBtnTapped):
        state.screen = .parentRequired
        return .none
      case (.parentRequired, .primaryBtnTapped):
        state.screen = .hiThere
        return .none
      case (.explainSetPin, .primaryBtnTapped):
        state.screen = .strongPin
        return .none
      case (.strongPin, .primaryBtnTapped):
        state.showingPinSheet = true
        return .none
      case (_, .setShowingPinSheet(false)):
        state.showingPinSheet = false
        return .none
      case (_, .pinSet(let pin)):
        self.passcode.save(pin)
        state.screen = .pinSet
        state.showingPinSheet = false
        return .none
      case (.pinSet, .lastBtnTapped):
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
  case explainSetPin
  case strongPin
  case pinSet
}
