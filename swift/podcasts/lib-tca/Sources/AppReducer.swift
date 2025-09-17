import ComposableArchitecture
import SharingGRDB

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    @Presents var mode: Mode.State?
    var nowPlaying = NowPlayingFeature.State()
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
    Scope(state: \.nowPlaying, action: \.nowPlaying) {
      NowPlayingFeature()
    }
    Reduce { state, action in
      switch action {
      case .mode(.presented(.onboarding(.finished(let passcode)))):
        state.mode = .podcasts(.init(passcode: passcode))
        return .run { _ in
          self.passcode.save(passcode)
        }
      case .mode(
        .presented(.podcasts(.destination(.presented(.show(.delegate(.episodePlayPauseTapped(
          let episode,
          let show
        )))))))
      ):
        return .send(.nowPlaying(.episodePlayPauseTapped(episode, show)))
      case .nowPlaying:
        return .none
      case .mode:
        return .none
      }
    }
    .ifLet(\.$mode, action: \.mode)
  }
}

extension AppReducer.State {
  var addingShow: Bool {
    if case .some(.podcasts(let podcasts)) = self.mode,
       case .some(.addShow) = podcasts.destination {
      return true
    }
    return false
  }
}

func unexpected(
  id: String,
  _ detail: String? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  let message = "Unexpected \(id)" + (detail.map { ": \($0)" } ?? "")
  reportIssue(message, fileID: fileID, filePath: filePath, line: line, column: column)
}
