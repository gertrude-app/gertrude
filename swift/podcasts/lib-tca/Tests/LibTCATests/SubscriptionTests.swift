import Combine
import ComposableArchitecture
import Dependencies
import LibViews
import SQLiteData
import StoreKit
import Testing

@testable import LibTCA

@MainActor struct SubscriptionTests {
  @Test func `purchase subscription during trial`() async throws {
    let finishedTxns = LockIsolated<[Transaction.ID]>([])
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.productIds = { ["cool.product"] }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.storekit.purchaseSubscription = { _ in .success(.mock) }
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

      await store.send(.view(.subscribeNowTapped)) {
        $0.purchaseInProgress = true
      }

      await store.receive(.finishPurchase) {
        $0.purchaseInProgress = false
      }

      sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(365))
      #expect(finishedTxns.value == [1])
    }
  }

  @Test func `resolve pending transaction full integration`() async throws {
    let finishedTxns = LockIsolated<[Transaction.ID]>([])
    let transactions = AsyncStream<TransactionData>.makeStream()
    try await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.productIds = { ["cool.product"] }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = .mock
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
      $0.storekit.transactionUpdates = { transactions.stream }
      $0.storekit.finishTransaction = { id in finishedTxns.withValue { $0.append(id) } }
      $0.storekit.verifiedCurrentEntitlements = { [] }
      $0.storekit.purchaseSubscription = { _ in .pending } // <-- attempt results in pending
    } operation: {
      try CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(30))
      var sub = dep(\.db).subscription()
      #expect(sub.purchasePendingSince == nil)

      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .podcasts(.init())
      }

      // go to settings screen
      await store.send(.mode(.presented(.podcasts(.settingsTapped)))) {
        $0.mode = .podcasts(.init(destination: .settings(.init())))
      }

      await store.send(
        .mode(
          .presented(.podcasts(.destination(.presented(.settings(.view(.subscribeNowTapped)))))),
        ),
      ) {
        $0.mode = .podcasts(.init(
          destination: .settings(.init(purchaseInProgress: true)),
        ))
      }

      sub = dep(\.db).subscription()
      #expect(sub.status == .trialing)
      #expect(sub.expiresAt == .reference + .days(30))
      #expect(sub.purchasePendingSince == .reference)

      transactions.continuation.yield(.mock)

      await store.receive(
        .mode(.presented(.podcasts(.destination(.presented(.settings(.finishPurchase)))))),
      ) {
        $0.mode = .podcasts(.init(
          destination: .settings(.init(purchaseInProgress: false)),
        ))
      }

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

  @Test func `transaction revoked`() async throws {
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

  @Test func `transaction expires`() async throws {
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

  @Test func `family sharing subscription`() async throws {
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
        $0.mode = .podcasts(.init())
      }

      await store.receive(.processStoreKitTransaction(.mock, update: false))

      sub = dep(\.db).subscription()
      #expect(sub.status == .active)
      #expect(sub.expiresAt == .reference + .days(365))
      #expect(finishedTxns.value == []) // we don't finish currentEntitlements

      transactions.continuation.finish()
      await store.finish()
    }
  }

  @Test func `defeat repeat free trial attempt`() async throws {
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.migrateDeviceId = { _, _ in }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try Subscription
          .update {
            $0.createdAt = .reference
            $0.expiresAt = .reference + .days(30)
            $0.status = .trialing
          }
          .execute($0)
      }
      $0.device.vendorId = { nil }
      $0.storekit = .testValue
      $0.mainQueue = .immediate
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.keychain._load = { key in
        switch key {
        case .pincode:
          "123456".data(using: .utf8)
        case .installId:
          "\(UUID())".data(using: .utf8)
        case .installDate:
          "\(Date.reference.advanced(by: -.days(35)).timeIntervalSince1970)".data(using: .utf8)
        case .deviceId:
          nil
        }
      }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off
      var sub = dep(\.db).subscription()
      #expect(sub.status == .trialing)
      #expect(sub.expiresAt == .reference + .days(30))

      await store.send(.appDidLaunch)
      await store.finish()

      sub = dep(\.db).subscription()
      #expect(sub.status == .unpaid)
      #expect(sub.expiresAt == .reference - .days(5))
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
    revocationDate: nil,
  )
}
