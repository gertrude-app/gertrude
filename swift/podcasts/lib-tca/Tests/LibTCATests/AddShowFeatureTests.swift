import ComposableArchitecture
import Dependencies
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct AddShowFeatureTests {
  @Test func duplicateShowSubscriptionFailsGracefully() async throws {
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
        initialState: .init(passcode: 111_111, screen: .chooseArtworkPolicy(dupeFeed)),
        reducer: AddShowFeature.init
      )
      store.exhaustivity = .off

      let existingShow = dep(\.db).show(id: 1)
      #expect(existingShow?.feedUrl == dupeFeed)

      await store.send(.selectAllowArtworkTapped) {
        $0.screen = .subscribing
      }

      await store.receive(.delegate(.alert("You are already subscribed to this show.")))
      #expect(dismissed.value == false)
      await clock.advance(by: .seconds(2))
      #expect(dismissed.value == true)

      let allShows = dep(\.db).tryRead {
        try Show.all.fetchAll($0)
      }
      #expect(allShows.map(\.id) == [Show.ID(1)])
    }
  }
}
