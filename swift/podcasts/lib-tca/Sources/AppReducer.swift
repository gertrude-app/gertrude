import ComposableArchitecture

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    var nowPlaying: NowPlayingFeature.State?
    @Presents var mode: Mode.State?
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Mode {
    case podcasts(PodcastsFeature)
    case onboarding(OnboardingFeature)
  }

  enum Action: Equatable {
    case nowPlaying(NowPlayingFeature.Action)
    case mode(PresentationAction<Mode.Action>)
  }

  @Dependency(\.passcode) var passcode

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .mode(.presented(.onboarding(.finished(let passcode)))):
        state.mode = .podcasts(.init(passcode: passcode))
        return .run { _ in
          self.passcode.save(passcode)
        }
      case .nowPlaying:
        return .none
      case .mode:
        return .none
      }
    }
    .ifLet(\.$mode, action: \.mode)
    .ifLet(\.nowPlaying, action: \.nowPlaying) {
      NowPlayingFeature()
    }
  }
}

struct NowPlaying: Equatable {
  var episode: Episode
  var show: Show
  var isPlaying: Bool
  var minimized: Bool
}
