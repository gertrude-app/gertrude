import ComposableArchitecture
import Foundation
import LibCore
import SQLiteData

@Reducer
struct AppReducer: Sendable {
  @ObservableState
  struct State: Equatable {
    @Presents var mode: Mode.State?
    var nowPlaying = NowPlayingFeature.State()
    @Shared(.appInForeground) var appInForeground
    @Presents var alert: AlertState<AlertAction>?
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
    case alert(PresentationAction<AlertAction>)
  }

  enum AlertAction: Equatable {
    case dismiss
  }

  @Dependency(\.db) var database
  @Dependency(\.passcode) var passcode
  @Dependency(\.audio) var audio
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date) var date
  @Dependency(\.notificationCenter) var notificationCenter

  var body: some Reducer<State, Action> {
    Scope(state: \.nowPlaying, action: \.nowPlaying) {
      NowPlayingFeature()
    }
    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        if let passcode = self.passcode.load() {
          state.mode = .podcasts(PodcastsFeature.State(passcode: passcode))
        } else {
          state.mode = .onboarding(OnboardingFeature.State())
        }
        let nowPlayingId = state.nowPlaying.data?.episode.id
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
          },
          .run { _ in
            #if DEBUG
              try await self.mainQueue.sleep(for: .seconds(1))
              let events = self.database.tryRead { db in
                try Event.order { $0.createdAt.asc() }.fetchAll(db)
              }
              if events.isEmpty {
                print("EVENTS: (none)")
              } else {
                for event in events {
                  print("EVENT: \(event.createdAt): \(event.name) \(event.detail ?? "")")
                }
              }
            #endif
            try await self.mainQueue.sleep(for: .seconds(10))
            self.autoPruneDownloads(nowPlayingId)
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
      case .mode(.presented(.podcasts(.destination(.presented(.show(let showAction)))))):
        switch showAction {
        case .delegate(.episodePlayPauseTapped(let episode, let show)),
             .destination(.presented(.episode(.delegate(.episodePlayPauseTapped(
               let episode,
               let show
             ))))):
          return .send(.nowPlaying(.episodePlayPauseTapped(episode, show)))
        case .delegate(.error(let message)):
          state.alert = .init { TextState(message) }
          return .none
        default:
          return .none
        }
      case .alert(.presented(.dismiss)):
        state.alert = nil
        return .none
      case .nowPlaying(.delegate(.error(let message))):
        state.alert = .init { TextState(message) }
        return .none
      case .alert:
        return .none
      case .nowPlaying:
        return .none
      case .mode:
        return .none
      }
    }
    .ifLet(\.$mode, action: \.mode)
    .ifLet(\.$alert, action: \.alert)
  }

  func autoPruneDownloads(_ nowPlaying: Episode.ID?) {
    let episodes = self.database.tryRead { db in
      try Episode
        .whereDownloadCanBeDeleted(nowPlaying: nowPlaying, now: self.date.now)
        .fetchAll(db)
    }
    if episodes.isEmpty { return }
    episodes.forEach { $0.removeLocalAudioFile() }
    self.database.tryWrite { db in
      try Episode
        .update { $0.downloadedAt = nil }
        .where { $0.id.in(episodes.map(\.id)) }
        .execute(db)
    }
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

extension AppReducer.Mode {
  var isPodcasts: Bool {
    if case .podcasts = self {
      return true
    }
    return false
  }
}

func unexpected(
  id: String,
  _ detail: String? = nil,
  assert: Bool = false,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  file: StaticString = #file,
  line: UInt = #line,
  column: UInt = #column
) {
  let message = "Unexpected \(id)" + (detail.map { ": \($0)" } ?? "")
  reportIssue(message, fileID: fileID, filePath: filePath, line: line, column: column)
  #if DEBUG
    if assert {
      assertionFailure(message, file: file, line: line)
    }
  #endif
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  static var appInForeground: Self {
    Self[.inMemory("appInForeground"), default: true]
  }
}
