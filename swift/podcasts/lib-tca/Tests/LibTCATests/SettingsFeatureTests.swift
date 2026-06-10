import ComposableArchitecture
import Dependencies
import Foundation
import LibViews
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct SettingsFeatureTests {
  @Test func `subscribe now is blocked entirely when no pincode exists`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(initialState: .init()) { SettingsFeature() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.send(.view(.subscribeNowTapped))
      #expect(store.state.pinChallenge == nil)
      #expect(store.state.claimFlow == nil)
    }
  }

  @Test func `unclaimed subscribe now presents the pin gate, not the claim flow`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    keychainStore
      .withValue { $0[KeychainClient.Key.pincode.rawValue] = "111111".data(using: .utf8)! }
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(initialState: .init()) { SettingsFeature() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      #expect(!store.state.isClaimed)

      await store.send(.view(.subscribeNowTapped))
      #expect(store.state.pinChallenge != nil)
      #expect(store.state.claimFlow == nil)
    }
  }

  @Test func `verifying the pin gate opens the claim flow at showing code`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    keychainStore
      .withValue { $0[KeychainClient.Key.pincode.rawValue] = "111111".data(using: .utf8)! }
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
      $0.haptics.notification = { _ in }
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(initialState: .init()) { SettingsFeature() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.send(.view(.subscribeNowTapped))
      #expect(store.state.pinChallenge != nil)

      await store.send(.pinChallenge(.pincodeVerified))
      await store.receive(.pinChallenge(.delegate(.verified)))
      #expect(store.state.pinChallenge == nil)
      #expect(store.state.claimFlow == nil)

      await store.send(.pinChallengeDismissed)
      #expect(store.state.claimFlow?.step == .showingCode)
    }
  }

  @Test func `cancelling the pin gate does not open the claim flow`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    keychainStore
      .withValue { $0[KeychainClient.Key.pincode.rawValue] = "111111".data(using: .utf8)! }
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(initialState: .init()) { SettingsFeature() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.send(.view(.subscribeNowTapped))
      #expect(store.state.pinChallenge != nil)

      await store.send(.pinChallenge(.pincodeCancelled))
      await store.receive(.pinChallenge(.delegate(.cancelled)))
      #expect(store.state.pinChallenge == nil)

      await store.send(.pinChallengeDismissed)
      #expect(store.state.claimFlow == nil)
      #expect(!store.state.pendingClaimAfterPin)
    }
  }

  @Test func `failed pin entry keeps the gate up and does not open the claim flow`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    keychainStore
      .withValue { $0[KeychainClient.Key.pincode.rawValue] = "111111".data(using: .utf8)! }
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
      $0.haptics.notification = { _ in }
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(initialState: .init()) { SettingsFeature() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.send(.view(.subscribeNowTapped))
      await store.send(.pinChallenge(.pincodeFailed))
      #expect(store.state.pinChallenge != nil)
      #expect(store.state.claimFlow == nil)
    }
  }

  @Test func `claimed subscribe now skips the pin gate and opens payment`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    keychainStore.withValue {
      $0[KeychainClient.Key.pincode.rawValue] = "111111".data(using: .utf8)!
      $0[KeychainClient.Key.amToken.rawValue] = UUID().uuidString.data(using: .utf8)!
    }
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(initialState: .init()) { SettingsFeature() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      #expect(store.state.isClaimed)

      await store.send(.view(.subscribeNowTapped))
      #expect(store.state.pinChallenge == nil)
      #expect(store.state.claimFlow?.step == .payment)
    }
  }

  @Test func `claiming inside the flow flips settings to claimed on dismiss`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    keychainStore
      .withValue { $0[KeychainClient.Key.pincode.rawValue] = "111111".data(using: .utf8)! }
    try await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
      $0.haptics.notification = { _ in }
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(initialState: .init()) { SettingsFeature() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.send(.view(.subscribeNowTapped))
      await store.send(.pinChallenge(.pincodeVerified))
      await store.receive(.pinChallenge(.delegate(.verified)))
      await store.send(.pinChallengeDismissed)
      #expect(store.state.claimFlow?.step == .showingCode)

      keychainStore.withValue {
        $0[KeychainClient.Key.amToken.rawValue] = UUID().uuidString.data(using: .utf8)!
      }
      await store.send(.claimFlow(.dismiss))
      #expect(store.state.isClaimed)

      await store.send(.view(.subscribeNowTapped))
      #expect(store.state.pinChallenge == nil)
      #expect(store.state.claimFlow?.step == .payment)
    }
  }
}
