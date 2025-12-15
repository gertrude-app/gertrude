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

      await store.send(.onAppear) {
        $0.destination = .confirm(
          .init(titleVisibility: .visible) {
            TextState("Your free trial is ending soon!")
          } actions: {
            ButtonState(action: .confirmTrialEnding) {
              TextState("Subscribe now")
            }
            ButtonState(role: .cancel) {
              TextState("Dismiss")
            }
          } message: {
            TextState("Subscribe to continue using the app.")
          },
        )
      }

      record = dep(\.db).record(id: .trialEndingAlertShown)
      #expect(record != nil)

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
    try await withDependencies {
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
}
