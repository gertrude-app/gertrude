import ComposableArchitecture
import Dependencies
import Foundation
import PairQL
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct PinResetFeatureTests {
  @Test func `valid reset code advances to set new pin, keeping the existing pin`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    await withDependencies {
      $0.api.consumePinResetCode = { _ in } // server accepts the code
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect {}
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore, pincode: 111_111)
      $0.haptics.notification = { _ in }
    } operation: {
      let store = TestStore(initialState: .init(isClaimed: true)) { PinResetFeature() }
      store.exhaustivity = .off

      await store.send(.codeSubmitted(123_456))
      await store.skipReceivedActions()

      #expect(store.state.step == .setNewPin)
      // old pin survives until the new one overwrites it -> cancelling here can't strand a claimed device pin-less
      #expect(keychainStore.value[KeychainClient.Key.pincode.rawValue] == "111111"
        .data(using: .utf8))
    }
  }

  @Test func `bad reset code shows an error and records a failed attempt`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    await withDependencies {
      $0.api.consumePinResetCode = { _ in
        throw PqlError(
          id: "a",
          requestId: "b",
          type: .notFound,
          debugMessage: "bad code",
          appTag: .incorrectConfirmationCode, // the resolver's bad/expired/wrong-install signal
        )
      }
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect {}
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore, pincode: 111_111)
      $0.haptics.notification = { _ in }
    } operation: {
      let store = TestStore(initialState: .init(isClaimed: true)) { PinResetFeature() }
      store.exhaustivity = .off

      await store.send(.codeSubmitted(999_999))
      await store.skipReceivedActions()

      #expect(store.state.showCodeError) // inline error
      #expect(store.state.step == .enterCode) // stays on code entry
      // failure routed into the shared PinChallengeFeature -> a failed attempt is recorded
      let attempts = dep(\.db).tryRead { db -> [PinAttempt] in
        try PinAttempt.all.fetchAll(db)
      }
      #expect(attempts.count(where: { !$0.success }) == 1)
      #expect(keychainStore.value[KeychainClient.Key.pincode.rawValue] != nil) // pin untouched
    }
  }

  @Test func `transport failure shows an error but records no attempt`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    await withDependencies {
      $0.api
        .consumePinResetCode = { _ in
          throw URLError(.notConnectedToInternet)
        } // outage, not a bad code
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect {}
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore, pincode: 111_111)
    } operation: {
      let store = TestStore(initialState: .init(isClaimed: true)) { PinResetFeature() }
      store.exhaustivity = .off

      await store.send(.codeSubmitted(123_456))
      await store.skipReceivedActions()

      #expect(store.state.showCodeError) // inline error
      #expect(store.state.step == .enterCode) // stays on code entry
      // an outage must NOT count toward lockout -> no failed attempt recorded
      let attempts = dep(\.db).tryRead { db -> [PinAttempt] in
        try PinAttempt.all.fetchAll(db)
      }
      #expect(attempts.isEmpty)
      #expect(keychainStore.value[KeychainClient.Key.pincode.rawValue] != nil) // pin untouched
    }
  }

  @Test func `setting a new pin saves it and dismisses`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let isDismissed = LockIsolated(false)
    await withDependencies {
      $0.api.consumePinResetCode = { _ in }
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect { isDismissed.setValue(true) }
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore, pincode: 111_111)
      $0.haptics.notification = { _ in }
    } operation: {
      let store = TestStore(initialState: .init(isClaimed: true)) { PinResetFeature() }
      store.exhaustivity = .off

      await store.send(.codeSubmitted(123_456))
      await store.skipReceivedActions()
      #expect(store.state.step == .setNewPin)

      await store.send(.newPinSubmitted(654_321))
      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.pincode.rawValue]
        == "654321".data(using: .utf8))
      #expect(isDismissed.value)
      await Task.yield()
      #expect(loggedEventIds().contains("5f2c8e04"))
    }
  }

  @Test func `unclaimed device starts on the support step`() throws {
    withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(isClaimed: false)) { PinResetFeature() }
      #expect(store.state.step == .unclaimed)
    }
  }

  @Test func `cancelling dismisses the flow`() async throws {
    let isDismissed = LockIsolated(false)
    await withDependencies {
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect { isDismissed.setValue(true) }
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]), pincode: 111_111)
    } operation: {
      let store = TestStore(initialState: .init(isClaimed: true)) { PinResetFeature() }
      store.exhaustivity = .off

      await store.send(.cancelTapped)
      await store.finish()
      #expect(isDismissed.value)
    }
  }
}
