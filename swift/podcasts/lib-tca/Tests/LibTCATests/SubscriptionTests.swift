import Combine
import ComposableArchitecture
import Dependencies
import LibViews
import SQLiteData
import StoreKit
import StoreKitTest
import Testing

@testable import LibTCA

@MainActor struct SubscriptionTests {
  @Test func purchaseSubscriptionDuringTrial() async throws {
    let finishedTxns = LockIsolated<[Transaction.ID]>([])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.storekit.purchaseSubscription = { .success(.mock) }
      $0.storekit.finishTransaction = { id in
        finishedTxns.withValue { $0.append(id) }
      }
    } operation: {
      // assert migration creates initial trialing subscription
      var sub = dep(\.db).subscription()
      #expect(sub.status == .trialing)

      // set it to a date we control, for rest of test
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(30))

      let store = TestStore(initialState: .init(), reducer: SettingsFeature.init)

      sub = dep(\.db).subscription()
      #expect(sub.status == .trialing)
      #expect(sub.expiresAt == .reference + .days(30))

      await store.send(.subscribeNowTapped)

      sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(365))
      #expect(finishedTxns.value == [1])
    }
  }

  @Test func resolvePendingTransaction_fullIntegration() async throws {
    let finishedTxns = LockIsolated<[Transaction.ID]>([])
    let transactions = AsyncStream<TransactionData>.makeStream()
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = .mock
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
      $0.storekit.transactionUpdates = { transactions.stream }
      $0.storekit.finishTransaction = { id in finishedTxns.withValue { $0.append(id) } }
      $0.storekit.verifiedCurrentEntitlements = { [] }
      $0.storekit.purchaseSubscription = { .pending } // <-- purchase attempt results in pending
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(30))
      var sub = dep(\.db).subscription()
      #expect(sub.purchasePendingSince == nil)

      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .podcasts(.init(passcode: 111_111))
      }

      // go to settings screen
      await store.send(.mode(.presented(.podcasts(.settingsTapped)))) {
        $0.mode = .podcasts(.init(
          passcode: 111_111,
          destination: .settings(.init())
        ))
      }

      await store.send(
        .mode(.presented(.podcasts(.destination(.presented(.settings(.subscribeNowTapped))))))
      )

      sub = dep(\.db).subscription()
      #expect(sub.status == .trialing)
      #expect(sub.expiresAt == .reference + .days(30))
      #expect(sub.purchasePendingSince == .reference)

      transactions.continuation.yield(.mock)

      await store.receive(.processStoreKitTransaction(.mock, update: true))

      sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(365))
      #expect(sub.purchasePendingSince == nil)
      #expect(finishedTxns.value == [1])

      transactions.continuation.finish()
      await store.finish()
    }
  }

  @Test func transactionRevoked() async throws {
    let finishedTxns = LockIsolated<[Transaction.ID]>([])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.storekit.finishTransaction = { id in finishedTxns.withValue { $0.append(id) } }
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(174))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      // just directly send the update, the integration test above covers
      // the integration of the stream of updates to this action
      var revoked: TransactionData = .mock
      revoked.revocationDate = .reference - .days(3)
      await store.send(.processStoreKitTransaction(revoked, update: true))

      let sub = dep(\.db).subscription()
      #expect(sub.status == .unpaid)
      #expect(sub.expiresAt == .reference - .days(3))
      #expect(sub.purchasePendingSince == nil)
    }
  }

  @Test func transactionExpires() async throws {
    let finishedTxns = LockIsolated<[Transaction.ID]>([])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.storekit.finishTransaction = { id in finishedTxns.withValue { $0.append(id) } }
    } operation: {
      try CurrentSubscription.set(status: .active, expiringAt: .reference + .days(174))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      // just directly send the update, the integration test above covers
      // the integration of the stream of updates to this action
      var expired: TransactionData = .mock
      expired.expirationDate = .reference - .days(3)
      await store.send(.processStoreKitTransaction(expired, update: true))

      let sub = dep(\.db).subscription()
      #expect(sub.status == .unpaid)
      #expect(sub.expiresAt == .reference - .days(3))
      #expect(sub.purchasePendingSince == nil)
    }
  }

  @Test func familySharingSubscription() async throws {
    let transactions = AsyncStream<TransactionData>.makeStream()
    let finishedTxns = LockIsolated<[Transaction.ID]>([])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = .mock
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
      $0.storekit.verifiedCurrentEntitlements = { [.mock] }
      $0.storekit.transactionUpdates = { transactions.stream }
      $0.storekit.finishTransaction = { id in finishedTxns.withValue { $0.append(id) } }
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(30))
      var sub = dep(\.db).subscription()
      #expect(sub.status == .trialing)
      #expect(sub.expiresAt == .reference + .days(30))

      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .podcasts(.init(passcode: 111_111))
      }

      await store.receive(.processStoreKitTransaction(.mock, update: false))

      sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(365))
      #expect(finishedTxns.value == [1])

      transactions.continuation.finish()
      await store.finish()
    }
  }
}

extension TransactionData {
  static let mock = Self(
    id: 1,
    productID: "cool.product",
    originalID: 1,
    purchaseDate: .reference,
    expirationDate: .reference + .days(365),
    revocationDate: nil
  )
}
