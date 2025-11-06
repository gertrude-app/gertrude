import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct PodcastsFeatureTests {
  @Test func showsTrialConfirmDialogue() async throws {
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

  @Test func doesNotShowTrialDialogueWhenAlreadyShown() async throws {
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
}
