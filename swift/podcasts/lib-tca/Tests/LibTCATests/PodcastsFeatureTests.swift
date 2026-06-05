import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct PodcastsFeatureTests {
  @Test func `shows trial confirm dialogue`() async throws {
    let clock = TestClock()
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.continuousClock = clock
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(4))

      var record = dep(\.db).record(id: .trialEndingAlertShown)
      #expect(record == nil)

      let store = TestStore(initialState: .init(), reducer: PodcastsFeature.init)
      store.exhaustivity = .off

      await store.send(.onAppear)

      record = dep(\.db).record(id: .trialEndingAlertShown)
      #expect(record != nil)
      #expect(store.state.destination?.confirm != nil)

      await store.send(.destination(.presented(.confirm(.confirmTrialEnding)))) {
        $0.destination = .settings(.init())
      }

      await store.send(.onAppear)

      await store.finish()
    }
  }

  @Test func `does not show trial dialogue when already shown`() async throws {
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.continuousClock = TestClock()
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(4))
      dep(\.db).insertRecord(id: .trialEndingAlertShown)

      let store = TestStore(initialState: .init(), reducer: PodcastsFeature.init)
      store.exhaustivity = .off

      await store.send(.onAppear) {
        $0.destination = nil
      }

      await store.finish()
    }
  }

  @Test func `settings change pin delegate presents add show with change pin screen`() async throws {
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.continuousClock = TestClock()
    } operation: {
      var state = PodcastsFeature.State()
      state.destination = .settings(.init())

      let store = TestStore(initialState: state, reducer: PodcastsFeature.init)
      store.exhaustivity = .off

      await store.send(.destination(.presented(.settings(.delegate(.changePinRequested))))) {
        $0.destination = .addShow(.init(screen: .changePinInstructions))
      }
    }
  }

  @Test func `review prompt shown after fourth subscribe`() async throws {
    let clock = TestClock()
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.continuousClock = clock
      $0.defaultDatabase = try! appDatabase {
        try Show.insert { [.mock(1), .mock(2), .mock(3)] }.execute($0)
      }
    } operation: {
      var state = PodcastsFeature.State()
      state.destination = .addShow(.init())

      let store = TestStore(initialState: state, reducer: PodcastsFeature.init)
      store.exhaustivity = .off

      // 3rd show add does not trigger prompt
      #expect(dep(\.db).record(id: .promptedReview) == nil)
      await store.send(.destination(.presented(.addShow(.subscribed(.mock(3)))))) {
        $0.destination = nil
      }
      await clock.advance(by: .seconds(2))
      #expect(dep(\.db).record(id: .promptedReview) == nil)

      // 4th show add does trigger prompt
      dep(\.db).tryWrite { try Show.insert { [.mock(4)] }.execute($0) }
      await store.send(.addShowTapped) {
        $0.destination = .addShow(.init())
      }
      await store.send(.destination(.presented(.addShow(.subscribed(.mock(4)))))) {
        $0.destination = nil
      }
      await clock.advance(by: .seconds(1.5))
      await store.receive(.promptReview) {
        $0.destination = .requestReview(.init())
      }
      #expect(dep(\.db).record(id: .promptedReview) != nil)
      var numShows = try await dep(\.db).read { try Show.count().fetchOne($0) }
      #expect(numShows == 4)

      // deleting and then re-adding 4th show does not re-trigger prompt
      dep(\.db).tryWrite { try Show.find(Show.ID(1)).delete().execute($0) }
      await store.send(.addShowTapped) {
        $0.destination = .addShow(.init())
      }
      dep(\.db).tryWrite { try Show.insert { [.mock(5)] }.execute($0) }
      await store.send(.destination(.presented(.addShow(.subscribed(.mock(5)))))) {
        $0.destination = nil
      }
      await clock.advance(by: .seconds(1.5))
      numShows = try await dep(\.db).read { try Show.count().fetchOne($0) }
      #expect(numShows == 4)
      store.assert { $0.destination = nil }
    }
  }
}
