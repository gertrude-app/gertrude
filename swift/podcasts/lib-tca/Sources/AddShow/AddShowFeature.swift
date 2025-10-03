import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct AddShowFeature {
  @ObservableState
  struct State: Equatable {
    enum Screen: Equatable {
      case enteringPin
      case choosingMethod
      case searching
      case addingByUrl
      case chooseArtworkPolicy(String)
      case subscribing
      case subscribeError
    }

    var passcode: Int
    var screen: Screen = .enteringPin
    var lockout: Date? = .pinLockout()
    var searchText: String = ""
    var searchResults: [SearchResult] = []
  }

  enum Action: Equatable {
    case passcodeVerified
    case passcodeFailed
    case passcodeCancelled
    case selectSearchTapped
    case selectAddByUrlTapped
    case selectAllowArtworkTapped
    case selectDontAllowArtworkTapped
    case setSearchText(String)
    case searchSetDebounced
    case selectShow(SearchResult)
    case setSearchResults([SearchResult])
    case setScreen(State.Screen)
    case subscribed(Show)
    case addByUrlSubmitted(String)
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.defaultDatabase) var db
  @Dependency(\.date.now) var now
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.haptics) var haptics

  private enum CancelID { case search }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .setSearchText(let text):
        state.searchText = text
        return .none

      case .setScreen(let screen):
        state.screen = screen
        return .none

      case .searchSetDebounced:
        guard !state.searchText.isEmpty else {
          return .none
        }
        return .run { [text = state.searchText] send in
          // TODO: handle errors
          let results = try await self.podcasts.search(text)
          await send(.setSearchResults(results))
        }
        .cancellable(id: CancelID.search)

      case .setSearchResults(let results):
        state.searchResults = results
        return .none

      case .passcodeVerified:
        self.insertAttempt(success: true)
        state.screen = .choosingMethod
        state.lockout = .pinLockout()
        return .run { _ in
          await self.haptics.notification(.success)
        }

      case .passcodeFailed:
        self.insertAttempt(success: false)
        state.lockout = .pinLockout()
        return .run { _ in
          await self.haptics.notification(.error)
        }

      case .passcodeCancelled:
        return .run { _ in
          await self.dismiss()
        }

      case .selectSearchTapped:
        state.screen = .searching
        return .none

      case .selectAddByUrlTapped:
        state.screen = .addingByUrl
        return .none

      case .selectShow(let show):
        state.screen = .chooseArtworkPolicy(show.feedUrl)
        return .none

      case .addByUrlSubmitted(let input):
        let feedUrl = input.starts(with: "http") ? input : "https://\(input)"
        state.screen = .chooseArtworkPolicy(feedUrl)
        return .none

      case .selectDontAllowArtworkTapped, .selectAllowArtworkTapped:
        guard case .chooseArtworkPolicy(let feedUrl) = state.screen else {
          reportIssue("Unexpected action \(action) in state \(state)")
          return .none
        }
        state.screen = .subscribing
        return self.subscribe(to: feedUrl, artwork: action == .selectAllowArtworkTapped)

      case .subscribed:
        return .none
      }
    }
  }

  func subscribe(to feedUrl: String, artwork withArtwork: Bool) -> Effect<Action> {
    .run { send in
      do {
        let feed = try await self.podcasts.getFeed(feedUrl)
        let show = self.db.tryWrite { db in
          try Show
            .insert { feed.show.toShowDraft(showArtwork: withArtwork) }
            .returning(\.self)
            .fetchOne(db)
        }
        guard let show else {
          await send(.setScreen(.subscribeError))
          return
        }
        await self.podcasts.downloadArtwork(for: show)
        let episodes = feed.episodes.map { $0.toEpisodeDraft(showId: show.id, now: self.now) }
        try await self.db.write { db in
          try Episode
            .insert { episodes }
            .execute(db)
        }
        await send(.subscribed(show))
      } catch {
        await send(.setScreen(.subscribeError))
      }
    }
  }

  func insertAttempt(success: Bool) {
    withErrorReporting {
      try self.db.write { db in
        try PinAttempt.insert {
          PinAttempt.Draft(success: success, createdAt: self.now)
        }.execute(db)
      }
    }
  }
}

extension Date {
  static func pinLockout() -> Date? {
    @Dependency(\.defaultDatabase) var db
    @Dependency(\.date.now) var now

    let attempts: [Date] = withErrorReporting {
      try db.read { db in
        try PinAttempt
          .select(\.createdAt)
          .where { $0.success == false }
          .where { $0.createdAt > now.addingTimeInterval(-24 * 60 * 60 * 10) }
          .order { $0.createdAt.asc() }
          .fetchAll(db)
      }
    } ?? []

    guard let last = attempts.last, attempts.count >= 5 else {
      return nil
    }

    print(attempts, last, now, attempts.count)
    // 5 minute lockout for 5-10 failed attempts, 20 minute lockout for more than 10
    let lockout = last.addingTimeInterval(60 * 5 * (attempts.count > 10 ? 4 : 1))
    return lockout > now ? lockout : nil
  }
}
