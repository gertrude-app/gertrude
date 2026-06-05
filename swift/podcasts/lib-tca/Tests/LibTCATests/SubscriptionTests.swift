import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import PairQL
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

  @Test func `every AmSubscriptionState case maps to a local status`() {
    let now = Date.reference
    let exp = now + .days(30)

    let comp = AmSubscriptionState.complimentary.toLocal(now: now)
    #expect(comp.status == .complimentary)
    #expect(comp.expiresAt > now + .days(365 * 50))

    #expect(AmSubscriptionState.active(expiresAt: exp).toLocal(now: now).status == .active)
    #expect(AmSubscriptionState.active(expiresAt: exp).toLocal(now: now).expiresAt == exp)

    #expect(AmSubscriptionState.fullTrial(expiresAt: exp).toLocal(now: now).status == .trialing)
    #expect(AmSubscriptionState.fullTrial(expiresAt: exp).toLocal(now: now).expiresAt == exp)

    #expect(AmSubscriptionState.amTrial(expiresAt: exp).toLocal(now: now).status == .trialing)
    #expect(AmSubscriptionState.amTrial(expiresAt: exp).toLocal(now: now).expiresAt == exp)

    let legacy = AmSubscriptionState
      .legacyGrandfathered(accessEndsAt: exp, showMigrationNag: true, migrationUrl: nil)
      .toLocal(now: now)
    #expect(legacy.status == .active)
    #expect(legacy.expiresAt == exp)

    #expect(AmSubscriptionState.unpaid(remediationUrl: nil).toLocal(now: now).status == .unpaid)
    #expect(
      AmSubscriptionState.legacyExpired(paidAt: now, remediationUrl: nil)
        .toLocal(now: now).status == .unpaid,
    )
  }

  @Test func `claimed trial status stores token and writes account state`() async throws {
    let token = UUID()
    let keychainStore = LockIsolated<[String: Data]>([:])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getTrialStatus = {
        .claimed(token: token, childId: UUID(), childName: "Sally", subscription: .active(
          expiresAt: .reference + .days(300),
        ))
      }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore, pincode: 111_111, installDate: .reference)
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(2))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] == token.uuidString
        .data(using: .utf8))
      let sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(300))
    }
  }

  @Test func `account status authoritatively corrects stale local active`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = {
        .init(childId: UUID(), childName: "Sally", subscription: .unpaid(remediationUrl: nil))
      }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = claimedKeychain(token: UUID(), store: keychainStore)
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(365))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      #expect(dep(\.db).subscription().status == .unpaid)
    }
  }

  @Test func `confirmed 401 clears token and falls back to trial poll`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = {
        throw PqlError(id: "a", requestId: "b", type: .unauthorized, debugMessage: "no token")
      }
      $0.api.getTrialStatus = { .trialExpired(since: .reference - .days(1)) }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = claimedKeychain(token: UUID(), store: keychainStore)
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(365))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] == nil)
      #expect(dep(\.db).subscription().status == .unpaid)
    }
  }

  @Test func `network error on account status does not clear token`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let token = UUID()
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = { throw URLError(.timedOut) }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = claimedKeychain(token: token, store: keychainStore)
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(365))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] == token.uuidString
        .data(using: .utf8))
      #expect(dep(\.db).subscription().status == .active)
    }
  }

  @Test func `5xx on account status does not clear token and logs error`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let loggedEventIds = LockIsolated<[String]>([])
    let token = UUID()
    try await withDependencies {
      $0.api.logEvent = { id, _, _, _ in loggedEventIds.withValue { $0.append(id) } }
      $0.api.getAccountStatus = {
        throw PqlError(id: "a", requestId: "b", type: .serverError, debugMessage: "boom")
      }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = claimedKeychain(token: token, store: keychainStore)
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(365))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()
      await Task.yield()

      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] == token.uuidString
        .data(using: .utf8))
      #expect(loggedEventIds.value.contains("a1f4c2d9"))
    }
  }

  @Test func `spurious 401 self-heals via trial reclaim`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let reclaimToken = UUID()
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = {
        throw PqlError(id: "a", requestId: "b", type: .unauthorized, debugMessage: "no token")
      }
      $0.api.getTrialStatus = {
        .claimed(token: reclaimToken, childId: UUID(), childName: "Sally", subscription: .active(
          expiresAt: .reference + .days(200),
        ))
      }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = claimedKeychain(token: UUID(), store: keychainStore)
      $0.device.vendorId = { nil }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(365))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] == reclaimToken.uuidString
        .data(using: .utf8))
      let sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(200))
    }
  }
}
