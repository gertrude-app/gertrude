import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import PodcastRoute
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct SubscriptionTests {
  @Test func `server trial status sets trialing with server expiresAt`() async throws {
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getTrialStatus = { .trial(expiresAt: .reference + .days(20)) }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = .mock
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(30))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      let sub = dep(\.db).subscription()
      #expect(sub.status == .trialing)
      #expect(sub.expiresAt == .reference + .days(20))
    }
  }

  @Test func `server trial expired sets unpaid with server since date`() async throws {
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getTrialStatus = { .trialExpired(since: .reference - .days(2)) }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = .mock
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(5))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      let sub = dep(\.db).subscription()
      #expect(sub.status == .unpaid)
      #expect(sub.expiresAt == .reference - .days(2))
    }
  }

  @Test func `legacy grandfathered status leaves local subscription unchanged`() async throws {
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getTrialStatus = {
        .legacyGrandfathered(paidAt: .reference, expiresAt: .reference + .days(400))
      }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = .mock
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(100))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      let sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(100))
    }
  }
}
