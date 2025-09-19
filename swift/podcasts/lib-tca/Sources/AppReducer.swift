import ComposableArchitecture
import SharingGRDB

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    @Presents var mode: Mode.State?
    var nowPlaying = NowPlayingFeature.State()
    @Shared(.appInForeground) var appInForeground
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Mode {
    case podcasts(PodcastsFeature)
    case onboarding(OnboardingFeature)
  }

  enum Action: Equatable {
    case appDidLaunch
    case appInForegroundChanged(Bool)
    case nowPlaying(NowPlayingFeature.Action)
    case mode(PresentationAction<Mode.Action>)
  }

  @Dependency(\.passcode) var passcode
  @Dependency(\.audioPlayer) var audio
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.notificationCenter) var notificationCenter

  var body: some Reducer<State, Action> {
    Scope(state: \.nowPlaying, action: \.nowPlaying) {
      NowPlayingFeature()
    }
    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        return .merge(
          .publisher {
            self.audio.systemEvents()
              .map { .nowPlaying(.system($0)) }
              .receive(on: self.mainQueue)
          },
          .publisher {
            self.notificationCenter.appForegroundingEvents()
              .map { .appInForegroundChanged($0) }
              .receive(on: self.mainQueue)
          }
        )
      case .appInForegroundChanged(let foregrounded):
        state.$appInForeground.withLock { $0 = foregrounded }
        return .none
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
  file: StaticString = #file,
  line: UInt = #line,
  column: UInt = #column
) {
  let message = "Unexpected \(id)" + (detail.map { ": \($0)" } ?? "")
  reportIssue(message, fileID: fileID, filePath: filePath, line: line, column: column)
  #if DEBUG
    assertionFailure(message, file: file, line: line)
  #endif
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  static var appInForeground: Self {
    Self[.inMemory("appInForeground"), default: true]
  }
}
