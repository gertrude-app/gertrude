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

  @Test func `changing search text cancels the stale in-flight search`() async throws {
    let clock = TestClock()
    let staleResult = SearchResult(
      id: 99,
      title: "Stale Result",
      artistName: "Old Query",
      feedUrl: "https://example.com/stale.rss",
      episodeCount: 1,
    )

    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.podcasts.search = { _ in
        try await clock.sleep(for: .seconds(1)) // keep the first search in-flight
        return [staleResult]
      }
    } operation: {
      let store = TestStore(
        initialState: .init(screen: .searching),
        reducer: AddShowFeature.init,
      )

      await store.send(.setSearchText("Thi")) {
        $0.searchText = "Thi"
        $0.searchInFlight = true
      }
      await store.send(.searchSetDebounced) // starts the search for "Thi", suspended on the clock

      await store.send(.setSearchText("This")) { // newer query must cancel the in-flight search
        $0.searchText = "This"
      }

      await clock
        .advance(by: .seconds(1)) // stale search would resolve here; cancelled, so no action
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

  @Test func `insecure feed url is silently upgraded, probed, and persisted as https`()
    async throws {
    let insecureFeed = "http://feeds.podtrac.com/2kW40nLGkY_a"
    let secureFeed = "https://feeds.podtrac.com/2kW40nLGkY_a"
    let fetched = LockIsolated<[String]>([])
    let probed = LockIsolated<[String]>([])

    await withDependencies {
      $0.date = .constant(.reference)
      $0.continuousClock = TestClock()
      $0.defaultDatabase = try! appDatabase()
      $0.podcasts.getFeed = { url in
        fetched.setValue(fetched.value + [url])
        return Feed(
          show: .mock(1) { $0.sourceUrl = url },
          episodes: [.mock(1, showId: 1)],
        )
      }
      $0.podcasts.canReachSecurely = { url in
        probed.setValue(probed.value + [url])
        return true
      }
    } operation: {
      let store = TestStore(
        initialState: .init(screen: .chooseArtworkPolicy(insecureFeed)),
        reducer: AddShowFeature.init,
      )
      store.exhaustivity = .off

      await store.send(.selectAllowArtworkTapped) {
        $0.screen = .subscribing
      }
      await store.receive(\.subscribed)

      #expect(fetched.value == [secureFeed]) // never attempted over cleartext
      #expect(probed.value == ["https://mock1.com/episode1.mp3"])

      let shows = dep(\.db).tryRead { try Show.all.fetchAll($0) }
      #expect(shows.map(\.feedUrl) == [secureFeed]) // https persisted, so refreshes work
    }
  }

  @Test func `feeds unreachable over https are refused with the insecure message`() async throws {
    let probeSucceeds = LockIsolated(false)
    let feedThrows = LockIsolated(true)

    await withDependencies {
      $0.date = .constant(.reference)
      $0.continuousClock = TestClock()
      $0.defaultDatabase = try! appDatabase()
      $0.podcasts.getFeed = { url in
        if feedThrows.value { throw PodcastFeedError.networkError }
        return Feed(show: .mock(1) { $0.sourceUrl = url }, episodes: [.mock(1, showId: 1)])
      }
      $0.podcasts.canReachSecurely = { _ in probeSucceeds.value }
    } operation: {
      let store = TestStore(
        initialState: .init(screen: .chooseArtworkPolicy("http://funny115.com/historians.xml")),
        reducer: AddShowFeature.init,
      )
      store.exhaustivity = .off

      await store.send(.selectAllowArtworkTapped)
      await store.receive(.delegate(.alert(lstr(.addShowInsecureError))))

      feedThrows.setValue(false) // feed now loads, but its media is cleartext-only
      await store.send(.setScreen(.chooseArtworkPolicy("http://funny115.com/historians.xml")))
      await store.send(.selectAllowArtworkTapped)
      await store.receive(.delegate(.alert(lstr(.addShowInsecureError))))

      #expect(dep(\.db).tryRead { try Show.all.fetchAll($0) }.isEmpty) // no half-added show

      feedThrows.setValue(true) // an https feed failing is an ordinary error, not an https problem
      await store.send(.setScreen(.chooseArtworkPolicy("https://example.com/feed.rss")))
      await store.send(.selectAllowArtworkTapped)
      await store.receive(.delegate(.alert(lstr(.addShowError))))
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
