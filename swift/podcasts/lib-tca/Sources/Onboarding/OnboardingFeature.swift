import ComposableArchitecture
import SwiftUI

@Reducer
struct OnboardingFeature {
  @ObservableState
  struct State: Equatable {
    var screen: OnboardingScreen = .hiThere
    var showingPasscodeSheet: Bool = false
    @Presents var claimFlow: ClaimFlow.State?
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
    case claimFlow(PresentationAction<ClaimFlow.Action>)
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
        state.screen = .explainAccountRequired
        return .none
      case (.areYouTheParent, .secondaryBtnTapped):
        state.screen = .parentRequired
        log(.info("4936b4ff"), "onboarding, not parent")
        return .none
      case (.parentRequired, .primaryBtnTapped):
        state.screen = .hiThere
        return .none
      case (.explainAccountRequired, .primaryBtnTapped):
        state.screen = .connectAccountOrSkip
        return .none
      case (.connectAccountOrSkip, .primaryBtnTapped):
        state.claimFlow = ClaimFlow.State(context: .onboarding, initialStep: .showingCode)
        return .none
      case (.connectAccountOrSkip, .secondaryBtnTapped):
        state.screen = .explainSetPasscode
        return .none
      case (_, .claimFlow(.dismiss)):
        state.screen = .explainSetPasscode
        return .none
      case (_, .claimFlow):
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
        state.showingPasscodeSheet = false
        return .run { send in
          await self.haptics.notification(.success)
          await send(.finished(passcode))
        }
      case (_, .finished):
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
    .ifLet(\.$claimFlow, action: \.claimFlow) {
      ClaimFlow()
    }
  }

  func shouldNotBeOnboarding() -> Bool {
    self.keychain.loadPincode() != nil
  }
}

enum OnboardingScreen: Equatable {
  case hiThere
  case areYouTheParent
  case parentRequired
  case explainAccountRequired
  case connectAccountOrSkip
  case explainSetPasscode
  case strongPasscode
}
