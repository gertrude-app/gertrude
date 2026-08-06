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

  @Test func `five shakes on an unclaimed device trigger an authorized escape hatch`() async throws {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let numRequests = LockIsolated(0)
    await withDependencies {
      $0.api.pinResetEscapeHatch = {
        numRequests.withValue { $0 += 1 }
        return true // server recognized the allowlisted device id
      }
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect {}
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore, pincode: 111_111)
    } operation: {
      let store = TestStore(initialState: .init(isClaimed: false)) { PinResetFeature() }
      store.exhaustivity = .off
      #expect(store.state.step == .unclaimed) // no email-code path exists for these users

      for _ in 1 ... 4 {
        await store.send(.receivedShake)
      }
      #expect(numRequests.value == 0) // nothing hits the api until the 5th shake
      #expect(store.state.step == .unclaimed)

      await store.send(.receivedShake)
      await store.skipReceivedActions()

      #expect(numRequests.value == 1)
      #expect(store.state.step == .setNewPin) // parent picks their own new pin
      #expect(store.state.timesShaken == 0)
      // old pin survives until the parent commits a new one
      #expect(keychainStore.value[KeychainClient.Key.pincode.rawValue] == "111111"
        .data(using: .utf8))
    }
  }

  @Test func `escape hatch stays shut until the server authorizes`() async throws {
    let response = LockIsolated<Result<Bool, any Error>>(.success(false))
    let numRequests = LockIsolated(0)
    await withDependencies {
      $0.api.pinResetEscapeHatch = {
        numRequests.withValue { $0 += 1 }
        return try response.value.get()
      }
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect {}
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]), pincode: 111_111)
    } operation: {
      // a claimed parent locked out of their gertrude account is stuck on .enterCode
      let store = TestStore(initialState: .init(isClaimed: true)) { PinResetFeature() }
      store.exhaustivity = .off

      await self.shakeFiveTimes(store)
      #expect(store.state.step == .enterCode) // silent denial, nothing reveals the mechanism
      #expect(store.state.timesShaken == 0) // counter re-arms for another attempt

      response.setValue(.failure(URLError(.notConnectedToInternet)))
      await self.shakeFiveTimes(store)
      #expect(store.state.step == .enterCode) // an outage must not read as authorization

      response.setValue(.success(true))
      await self.shakeFiveTimes(store)
      #expect(store.state.step == .setNewPin)

      await self.shakeFiveTimes(store)
      #expect(numRequests.value == 3) // shaking is inert once they're already setting a pin
    }
  }

  func shakeFiveTimes(_ store: TestStoreOf<PinResetFeature>) async {
    for _ in 1 ... 5 {
      await store.send(.receivedShake)
    }
    await store.skipReceivedActions(strict: false)
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
