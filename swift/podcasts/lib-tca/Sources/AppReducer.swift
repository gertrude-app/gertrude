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
  @Dependency(\.keychain) var keychain
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
        // TEMP: remove
        self.keychain.migrateAccessibility()

        if self.keychain.isFirstLaunch() {
          let installDate = self.date.now
          self.keychain.save(installDate: installDate)
          self.database.insertRecord(id: .installDate)

          let installId = UUID()
          self.keychain.save(installId: installId)
          self.database.insertRecord(id: .deviceId, value: "\(installId)")
        }

        if let passcode = self.keychain.loadPincode() {
          state.mode = .podcasts(PodcastsFeature.State(passcode: passcode))
          self.database.insertEvent(name: "appDidLaunch with passcode")
        } else {
          state.mode = .onboarding(OnboardingFeature.State())
          self.database.insertEvent(name: "appDidLaunch without passcode")
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
            try await self.mainQueue.sleep(for: .seconds(10))
            self.cleanupTasks(nowPlayingId)
          }
        )
      case .appInForegroundChanged(let foregrounded):
        state.$appInForeground.withLock { $0 = foregrounded }
        return .none
      case .mode(.presented(.onboarding(.finished(let pincode)))):
        state.mode = .podcasts(.init(passcode: pincode))
        return .run { _ in
          self.keychain.save(pincode: pincode)
          self.database.insertEvent(name: "saved pincode")
          self.database.insertRecord(id: .onboardingFinished)
          // TODO: log api
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
      case .mode(.presented(.onboarding(.delegate(.shouldNotBeOnboarding)))):
        if let passcode = self.keychain.loadPincode() {
          state.mode = .podcasts(PodcastsFeature.State(passcode: passcode))
          return .run { _ in
            self.database.insertEvent(name: "unexpected-73430b7b")
            // TODO: log api
          }
        } else {
          return .run { _ in
            self.database.insertEvent(name: "unexpected-9f4d7c2d")
            // TODO: await log api
            preconditionFailure("unreachable-9f4d7c2d")
          }
        }
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

  func cleanupTasks(_ nowPlaying: Episode.ID?) {
    self.autoPruneDownloads(nowPlaying)
    self.database.tryWrite { db in
      try Event
        .where { $0.createdAt.lt(self.date.now - .days(30)) }
        .delete()
        .execute(db)
    }
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
  var hideNowPlaying: Bool {
    if case .some(.podcasts(let podcasts)) = self.mode,
       case .some(.addShow) = podcasts.destination {
      return true
    } else if case .some(.onboarding) = self.mode {
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
