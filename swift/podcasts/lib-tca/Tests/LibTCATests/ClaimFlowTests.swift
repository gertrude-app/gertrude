import ComposableArchitecture
import Dependencies
import Foundation
import PodcastRoute
import Testing

@testable import LibTCA

@MainActor struct ClaimFlowTests {
  @Test func `claim into active shows terminal success then dismisses`() async {
    let clock = TestClock()
    let token = UUID()
    let isDismissed = LockIsolated(false)
    let keychainStore = LockIsolated<[String: Data]>([:])
    let loggedEventIds = LockIsolated<[String]>([])
    await withDependencies {
      $0.api.logEvent = { id, _, _, _ in loggedEventIds.withValue { $0.append(id) } }
      $0.api.createClaimCode = { .init(code: 123_456, expiresAt: .reference + .days(1)) }
      $0.api.getTrialStatus = {
        .claimed(token: token, childId: UUID(), childName: "Sally", subscription: .active(
          expiresAt: .reference + .days(300),
        ))
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect { isDismissed.setValue(true) }
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
    } operation: {
      let store = TestStore(initialState: .init(context: .modal, initialStep: .showingCode)) {
        ClaimFlow()
      }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.receive(\.claimCodeResponse)
      #expect(store.state.claimCode == 123_456)

      await clock.advance(by: .seconds(5))
      await store.receive(\.polled)
      #expect(store.state.step == .success)
      #expect(store.state.successIsTerminal)
      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] == token.uuidString
        .data(using: .utf8))
      #expect(dep(\.db).subscription().status == .active)

      await store.send(.doneTapped)
      await store.finish()
      #expect(isDismissed.value)
      await Task.yield()
      #expect(loggedEventIds.value.contains("9b9ea2d6"))
    }
  }

  @Test func `claim into unpaid shows neutral success advancing to payment`() async {
    let clock = TestClock()
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.createClaimCode = { .init(code: 654_321, expiresAt: .reference + .days(1)) }
      $0.api.getTrialStatus = {
        .claimed(token: UUID(), childId: UUID(), childName: "Sally", subscription: .unpaid(
          remediationUrl: nil,
        ))
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(context: .modal, initialStep: .showingCode)) {
        ClaimFlow()
      }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await clock.advance(by: .seconds(5))
      await store.receive(\.polled)
      #expect(store.state.step == .success)
      #expect(!store.state.successIsTerminal)

      await store.send(.nextTapped)
      #expect(store.state.step == .payment)
    }
  }

  @Test func `entering at payment mints no claim code`() async {
    let clock = TestClock()
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = {
        .init(childId: UUID(), childName: "Sally", subscription: .unpaid(remediationUrl: nil))
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect {}
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(
        initialState: .init(
          context: .modal,
          initialStep: .payment,
          entitlement: .unpaid(remediationUrl: nil),
        ),
      ) { ClaimFlow() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      #expect(store.state.step == .payment)
      #expect(store.state.claimCode == nil)

      await store.send(.notNowTapped)
      await store.finish()
    }
  }

  @Test func `payment poll into entitled state writes row and dismisses`() async throws {
    let clock = TestClock()
    let isDismissed = LockIsolated(false)
    let loggedEventIds = LockIsolated<[String]>([])
    try await withDependencies {
      $0.api.logEvent = { id, _, _, _ in loggedEventIds.withValue { $0.append(id) } }
      $0.api.getAccountStatus = {
        .init(childId: UUID(), childName: "Sally", subscription: .active(
          expiresAt: .reference + .days(365),
        ))
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect { isDismissed.setValue(true) }
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let store = TestStore(
        initialState: .init(
          context: .modal,
          initialStep: .payment,
          entitlement: .unpaid(remediationUrl: nil),
        ),
      ) { ClaimFlow() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await clock.advance(by: .seconds(5))
      await store.receive(\.accountStatusResponse)
      await store.finish()
      #expect(dep(\.db).subscription().status == .active)
      #expect(isDismissed.value)
      await Task.yield()
      #expect(loggedEventIds.value.contains("c6cae011"))
    }
  }

  @Test func `payment poll still unpaid stays on payment without dismiss`() async {
    let clock = TestClock()
    let isDismissed = LockIsolated(false)
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = {
        .init(childId: UUID(), childName: "Sally", subscription: .unpaid(remediationUrl: nil))
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect { isDismissed.setValue(true) }
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(
        initialState: .init(
          context: .modal,
          initialStep: .payment,
          entitlement: .unpaid(remediationUrl: nil),
        ),
      ) { ClaimFlow() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await clock.advance(by: .seconds(5))
      await store.receive(\.accountStatusResponse)
      #expect(store.state.step == .payment)
      #expect(!isDismissed.value)

      await store.send(.notNowTapped)
      await store.finish()
    }
  }

  @Test func `payment not now cancels poll and dismisses`() async {
    let clock = TestClock()
    let isDismissed = LockIsolated(false)
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = {
        .init(childId: UUID(), childName: "Sally", subscription: .unpaid(remediationUrl: nil))
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.dismiss = DismissEffect { isDismissed.setValue(true) }
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(
        initialState: .init(
          context: .modal,
          initialStep: .payment,
          entitlement: .unpaid(remediationUrl: nil),
        ),
      ) { ClaimFlow() }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.send(.notNowTapped)
      await store.finish()
      #expect(isDismissed.value)
    }
  }

  @Test func `claim code creation failure shows retryable error`() async {
    let clock = TestClock()
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.createClaimCode = { throw ApiClient.ApiError.requestFailed }
      $0.api.getTrialStatus = { .trial(expiresAt: .reference + .days(5)) }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(context: .modal, initialStep: .showingCode)) {
        ClaimFlow()
      }
      store.exhaustivity = .off

      await store.send(.onAppear)
      await store.receive(\.claimCodeFailed)
      #expect(store.state.claimCodeFailed)

      await store.send(.cancelTapped)
      await store.finish()
    }
  }
}
