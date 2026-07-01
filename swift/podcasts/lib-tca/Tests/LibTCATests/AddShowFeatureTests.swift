import ComposableArchitecture
import Dependencies
import Foundation
import LibViews
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct AddShowFeatureTests {
  @Test func `search shows pending state while results load`() async throws {
    let result = SearchResult(
      id: 1,
      title: "This American Life",
      artistName: "This American Life",
      feedUrl: "https://feeds.simplecast.com/EmVW7VGp",
      episodeCount: 800,
    )

    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.podcasts.search = { query in
        #expect(query == "This")
        return [result]
      }
    } operation: {
      let store = TestStore(
        initialState: .init(screen: .searching),
        reducer: AddShowFeature.init,
      )

      await store.send(.setSearchText("This")) {
        $0.searchText = "This"
        $0.searchInFlight = true
      }

      await store.send(.searchSetDebounced)
      await store.receive(.setSearchResults([result])) {
        $0.searchResults = [result]
        $0.searchInFlight = false
      }
    }
  }

  @Test func `duplicate show subscription fails gracefully`() async throws {
    let dupeFeed = "https://example.com/feed.rss"
    let clock = TestClock()
    let dismissed = LockIsolated(false)

    await withDependencies {
      $0.date = .constant(.reference)
      $0.continuousClock = clock
      $0.dismiss = .init { dismissed.setValue(true) }
      $0.defaultDatabase = try! appDatabase {
        try Show.insert { [.mock(1) { $0.feedUrl = dupeFeed }] }.execute($0)
      }
      $0.podcasts.getFeed = { _ in
        Feed(show: .mock(2) { $0.sourceUrl = dupeFeed }, episodes: [])
      }
      $0.api.logEvent = { _, _, _, _ in }
    } operation: {
      let store = TestStore(
        initialState: .init(screen: .chooseArtworkPolicy(dupeFeed)),
        reducer: AddShowFeature.init,
      )
      store.exhaustivity = .off

      let existingShow = dep(\.db).show(id: 1)
      #expect(existingShow?.feedUrl == dupeFeed)

      await store.send(.selectAllowArtworkTapped) {
        $0.screen = .subscribing
      }

      await store.receive(.delegate(.alert(lstr(.addShowAlreadySubscribed))))
      #expect(dismissed.value == false)
      await clock.advance(by: .seconds(2))
      #expect(dismissed.value == true)

      let allShows = dep(\.db).tryRead {
        try Show.all.fetchAll($0)
      }
      #expect(allShows.map(\.id) == [Show.ID(1)])
    }
  }

  @Test func `pin change flow`() async throws {
    let keySaved = LockIsolated<[(KeychainClient.Key, Data)]>([])
    let clock = TestClock()
    let dismissed = LockIsolated(false)
    await withDependencies {
      $0.defaultDatabase = try! appDatabase()
      $0.date = .constant(.reference)
      $0.dismiss = .init { dismissed.setValue(true) }
      $0.api.logEvent = { _, _, _, _ in }
      $0.haptics.notification = { _ in }
      $0.continuousClock = clock
      $0.keychain._save = { key, data in
        keySaved.setValue(keySaved.value + [(key, data)])
      }
    } operation: {
      let store = TestStore(
        initialState: .init(screen: .changePinInstructions),
        reducer: AddShowFeature.init,
      )
      store.exhaustivity = .off

      await store.send(.changePinInstructionsOkTapped) {
        $0.screen = .enteringPin
        $0.resettingPin = true
      }

      await store.send(.pinChallenge(.pincodeVerified))
      await store.receive(.pinChallenge(.delegate(.verified))) {
        $0.screen = .settingNewPin
      }

      #expect(keySaved.value.isEmpty)

      await store.send(.newPinSubmitted(222_222)) {
        $0.resettingPin = false
      }

      #expect(keySaved.value.count == 1)
      #expect(keySaved.value.first?.0 == .pincode)
      #expect(keySaved.value.first?.1 == Data("\(222_222)".utf8))

      await store.receive(.delegate(.alert(lstr(.pinChangeSuccess))))

      #expect(dismissed.value == false)
      await clock.advance(by: .seconds(2))
      #expect(dismissed.value == true)
    }
  }
}
