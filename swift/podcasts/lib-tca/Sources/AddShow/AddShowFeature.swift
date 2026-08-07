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
      case changePinInstructions
      case settingNewPin
      case choosingMethod
      case searching
      case addingByUrl
      case chooseArtworkPolicy(String)
      case subscribing
    }

    var screen: Screen = .enteringPin
    var pinChallenge = PinChallengeFeature.State()
    var resettingPin: Bool = false
    var searchText: String = ""
    var searchResults: [SearchResult] = []
    var searchInFlight: Bool = false
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case alert(String)
    }

    case pinChallenge(PinChallengeFeature.Action)
    case newPinCancelled
    case changePinInstructionsOkTapped
    case newPinSubmitted(Int)
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
    case delegate(DelegateAction)
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.db) var db
  @Dependency(\.date.now) var now
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.api) var api
  @Dependency(\.keychain) var keychain
  @Dependency(\.continuousClock) var clock

  private enum CancelID { case search }

  var body: some Reducer<State, Action> {
    Scope(state: \.pinChallenge, action: \.pinChallenge) {
      PinChallengeFeature(logBaseId: "e86bd7f3") // e86bd7f3-1, e86bd7f3-2
    }
    Reduce { state, action in
      switch action {
      case .setSearchText(let text):
        state.searchText = text
        state.searchResults = []
        state.searchInFlight = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return .cancel(id: CancelID.search)

      case .setScreen(let screen):
        state.screen = screen
        return .none

      case .searchSetDebounced:
        let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
          state.searchInFlight = false
          return .none
        }
        return .run { send in
          await send(.setSearchResults((try? self.podcasts.search(query)) ?? []))
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)

      case .setSearchResults(let results):
        state.searchResults = results
        state.searchInFlight = false
        return .none

      case .pinChallenge(.delegate(.verified)):
        state.screen = state.resettingPin ? .settingNewPin : .choosingMethod
        return .none

      case .pinChallenge(.delegate(.cancelled)):
        return .run { _ in
          await self.dismiss()
        }

      case .pinChallenge:
        return .none

      case .newPinCancelled:
        return .run { _ in
          await self.dismiss()
        }

      case .changePinInstructionsOkTapped:
        state.resettingPin = true
        state.screen = .enteringPin
        return .none

      case .newPinSubmitted(let pin):
        state.resettingPin = false
        return .run { send in
          self.keychain.save(pincode: pin)
          log(.info, .library, "0c045f6c", detail: "to: \(pin.redacted)")
          await send(.delegate(.alert(lstr(.pinChangeSuccess))))
          try? await self.clock.sleep(for: .seconds(2))
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
        if let special = self.handleSpecialAction(input: input) {
          log(.info, .library, "2c229d59", detail: input)
          return special
        }
        log(.info, .library, "8524413f", detail: input)
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

      case .delegate:
        return .none
      }
    }
  }

  func subscribe(to requestedUrl: String, artwork withArtwork: Bool) -> EffectOf<AddShowFeature> {
    .run { send in
      let feedUrl = upgradeToHttps(requestedUrl)
      let upgraded = feedUrl != requestedUrl
      do {
        log(.info, .library, "7785c87b", detail: "\(feedUrl), artwork: \(withArtwork)")
        let feed = try await self.podcasts.getFeed(feedUrl)
        let existingShow = try await self.db.read { db in
          try Show
            .where { $0.feedUrl.eq(feedUrl) }
            .fetchOne(db)
        }
        if existingShow != nil {
          log(.info, .library, "b8139e22")
          await send(.delegate(.alert(lstr(.addShowAlreadySubscribed))))
          try? await self.clock.sleep(for: .seconds(2))
          await self.dismiss()
          return
        }
        if let audioUrl = feed.episodes.first?.audioUrl,
           await !self.podcasts.canReachSecurely(audioUrl) {
          log(.err, .library, "5d1f8a63", detail: "insecure media: \(audioUrl)")
          await send(.setScreen(.choosingMethod))
          await send(.delegate(.alert(lstr(.addShowInsecureError))))
          return
        }
        let show = try await self.db.write { db in
          try Show
            .insert { feed.show.toShowDraft(showArtwork: withArtwork) }
            .returning(\.self)
            .fetchOne(db)
        }
        guard let show else {
          log(.err, .library, "98916a65", detail: "db insert->nil: \(feedUrl)")
          await send(.setScreen(.choosingMethod))
          await send(.delegate(.alert(lstr(.addShowError))))
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
        log(.err, .library, "8c5abff7", detail: "\(feedUrl): \(error)")
        await send(.setScreen(.choosingMethod))
        await send(.delegate(.alert(lstr(upgraded ? .addShowInsecureError : .addShowError))))
      }
    }
  }
}
