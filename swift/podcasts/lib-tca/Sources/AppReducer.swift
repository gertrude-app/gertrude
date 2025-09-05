import ComposableArchitecture

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    @Presents var mode: Mode.State?
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Mode {
    case podcasts(PodcastsFeature)
    case onboarding(OnboardingFeature)
  }

  enum Action: Equatable {
    case appDidLaunch
    case mode(PresentationAction<Mode.Action>)
  }

  @Dependency(\.passcode) var passcode

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        state.mode = self.passcode.saved() ? .podcasts(.init()) : .onboarding(.init())
        return .none
      case .mode(.presented(.onboarding(.lastBtnTapped))):
        state.mode = .podcasts(.init())
        return .none
      case .mode:
        return .none
      }
    }
    .ifLet(\.$mode, action: \.mode)
  }
}
