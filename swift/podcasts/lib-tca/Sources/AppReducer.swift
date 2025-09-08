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
    case setMode(Mode.State)
  }

  @Dependency(\.passcode) var passcode

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        return .run { send in
          if await self.passcode.saved() {
            await send(.setMode(.podcasts(.init())))
          } else {
            await send(.setMode(.onboarding(.init())))
          }
        }
      case .setMode(let mode):
        state.mode = mode
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
