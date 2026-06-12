import ComposableArchitecture
import PodcastRoute
import SwiftUI

@Reducer
struct OnboardingFeature {
  @ObservableState
  struct State: Equatable {
    var screen: OnboardingScreen = .hiThere
    var showingPasscodeSheet: Bool = false
    var resumedAfterClaim: Bool = false
    var trialStatus: GetTrialStatus.Output?
    @Presents var claimFlow: ClaimFlow.State?

    var pinRecoveryAvailable: Bool {
      self.resumedAfterClaim || self.trialStatus?.isClaimed == true
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case shouldNotBeOnboarding
    }

    case onAppear
    case trialStatusResponse(GetTrialStatus.Output)
    case connectingTimedOut
    case primaryBtnTapped
    case secondaryBtnTapped
    case finished(Int)
    case setShowingPasscodeSheet(Bool)
    case passcodeSet(Int)
    case passcodeConfirmFailed
    case claimFlow(PresentationAction<ClaimFlow.Action>)
    case delegate(DelegateAction)
  }

  enum CancelID {
    case connecting
  }

  @Dependency(\.api) var api
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now
  @Dependency(\.db) var database
  @Dependency(\.keychain) var keychain
  @Dependency(\.haptics) var haptics

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch (state.screen, action) {
      case (_, .onAppear):
        guard state.trialStatus == nil else { return .none }
        return self.fetchTrialStatus()
      case (_, .trialStatusResponse(let output)):
        state.trialStatus = output
        guard state.screen == .connecting else { return .none }
        state.screen = output.isClaimed ? .accountDetected : .explainAccountRequired
        return .cancel(id: CancelID.connecting)
      case (_, .connectingTimedOut):
        guard state.screen == .connecting else { return .none }
        state.screen = .explainAccountRequired
        return .cancel(id: CancelID.connecting)
      case (.hiThere, .primaryBtnTapped):
        state.screen = .areYouTheParent
        return self.shouldNotBeOnboarding() ? .send(.delegate(.shouldNotBeOnboarding)) : .none
      case (.areYouTheParent, .primaryBtnTapped):
        switch state.trialStatus {
        case .claimed:
          state.screen = .accountDetected
          return .none
        case .some:
          state.screen = .explainAccountRequired
          return .none
        case .none:
          state.screen = .connecting
          return .merge(
            self.fetchTrialStatus(),
            .run { send in
              try await self.clock.sleep(for: .seconds(3))
              await send(.connectingTimedOut)
            },
          )
          .cancellable(id: CancelID.connecting)
        }
      case (.accountDetected, .primaryBtnTapped):
        state.screen = .explainSetPasscode
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
      case (_, .claimFlow(.presented(.polled(let output)))):
        state.trialStatus = output
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

  func fetchTrialStatus() -> EffectOf<OnboardingFeature> {
    .run { send in
      guard let output = try? await self.api.getTrialStatus() else { return }
      if case .claimed(let token, _, _, let subscription) = output {
        self.keychain.save(amToken: token)
        subscription.writeLocal(now: self.now)
      }
      await send(.trialStatusResponse(output))
    }
  }
}

extension GetTrialStatus.Output {
  var isClaimed: Bool {
    if case .claimed = self { true } else { false }
  }

  var claimedChildName: String? {
    if case .claimed(_, _, let childName, _) = self { childName } else { nil }
  }
}

enum OnboardingScreen: Equatable {
  case hiThere
  case areYouTheParent
  case parentRequired
  case connecting
  case accountDetected
  case explainAccountRequired
  case connectAccountOrSkip
  case explainSetPasscode
  case strongPasscode
}
