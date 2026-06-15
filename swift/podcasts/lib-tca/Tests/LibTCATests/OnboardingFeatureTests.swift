import ComposableArchitecture
import Dependencies
import Foundation
import PodcastRoute
import Testing

@testable import LibTCA

@MainActor struct OnboardingFeatureTests {
  @Test func `connect now presents claim flow then advances to passcode on dismiss`() async {
    await withDependencies {
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(
        trialStatus: .trial(expiresAt: .reference + .days(30)),
      )) { OnboardingFeature() }

      await store.send(.primaryBtnTapped) { $0.screen = .areYouTheParent }
      await store.send(.primaryBtnTapped) { $0.screen = .explainAccountRequired }
      await store.send(.primaryBtnTapped) { $0.screen = .connectAccountOrSkip }
      await store.send(.primaryBtnTapped) {
        $0.claimFlow = ClaimFlow.State(context: .onboarding, initialStep: .showingCode)
      }
      await store.send(.claimFlow(.dismiss)) {
        $0.screen = .explainSetPasscode
        $0.claimFlow = nil
      }
    }
  }

  @Test func `skip advances straight to passcode without a claim flow`() async {
    await withDependencies {
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(screen: .connectAccountOrSkip)) {
        OnboardingFeature()
      }

      await store.send(.secondaryBtnTapped) { $0.screen = .explainSetPasscode }
      #expect(store.state.claimFlow == nil)
      #expect(store.state.pinRecoveryAvailable == false)
    }
  }

  @Test func `setting the passcode sends finished`() async {
    await withDependencies {
      $0.keychain = dictKeychain(LockIsolated([:]))
      $0.haptics.notification = { _ in }
    } operation: {
      let store = TestStore(initialState: .init(screen: .strongPasscode)) {
        OnboardingFeature()
      }
      store.exhaustivity = .off

      await store.send(.primaryBtnTapped)
      #expect(store.state.showingPasscodeSheet)

      await store.send(.passcodeSet(123_456))
      await store.receive(\.finished)
    }
  }

  @Test func `claimed prefetch short-circuits the account screens`() async {
    await withDependencies {
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(
        screen: .areYouTheParent,
        trialStatus: .connected(
          token: UUID(),
          childId: UUID(),
          childName: "Sally",
          subscription: .active(expiresAt: .reference + .days(300)),
        ),
      )) { OnboardingFeature() }

      await store.send(.primaryBtnTapped) { $0.screen = .accountDetected }
      await store.send(.primaryBtnTapped) { $0.screen = .explainSetPasscode }
      #expect(store.state.pinRecoveryAvailable)
    }
  }

  @Test func `successful claim enables PIN recovery copy`() async {
    let output = GetTrialStatus.Output.connected(
      token: UUID(),
      childId: UUID(),
      childName: "Sally",
      subscription: .active(expiresAt: .reference + .days(300)),
    )
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(
        screen: .connectAccountOrSkip,
        claimFlow: .init(context: .onboarding),
      )) {
        OnboardingFeature()
      }
      store.exhaustivity = .off

      await store.send(.claimFlow(.presented(.polled(output))))
      #expect(store.state.pinRecoveryAvailable)

      await store.send(.claimFlow(.dismiss))
      #expect(store.state.screen == .explainSetPasscode)
      #expect(store.state.pinRecoveryAvailable)
    }
  }

  @Test func `trial prefetch routes the parent tap to the account explainer`() async {
    await withDependencies {
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(
        screen: .areYouTheParent,
        trialStatus: .trial(expiresAt: .reference + .days(30)),
      )) { OnboardingFeature() }

      await store.send(.primaryBtnTapped) { $0.screen = .explainAccountRequired }
    }
  }

  @Test func `pending parent tap connects then resolves to account detected on claim`() async {
    let clock = TestClock()
    let token = UUID()
    let keychainStore = LockIsolated<[String: Data]>([:])
    await withDependencies {
      $0.api.getTrialStatus = {
        .connected(
          token: token,
          childId: UUID(),
          childName: "Sally",
          subscription: .active(expiresAt: .reference + .days(300)),
        )
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(keychainStore)
    } operation: {
      let store = TestStore(initialState: .init(screen: .areYouTheParent)) { OnboardingFeature() }
      store.exhaustivity = .off

      await store.send(.primaryBtnTapped)
      #expect(store.state.screen == .connecting)

      await store.receive(\.trialStatusResponse)
      #expect(store.state.screen == .accountDetected)
      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] == token.uuidString
        .data(using: .utf8))

      await store.finish()
    }
  }

  @Test func `pending parent tap times out to the account explainer`() async {
    let clock = TestClock()
    await withDependencies {
      $0.api.getTrialStatus = {
        try await clock.sleep(for: .seconds(60))
        return .trial(expiresAt: .reference + .days(30))
      }
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(screen: .areYouTheParent)) { OnboardingFeature() }
      store.exhaustivity = .off

      await store.send(.primaryBtnTapped)
      #expect(store.state.screen == .connecting)

      await clock.advance(by: .seconds(3))
      await store.receive(\.connectingTimedOut)
      #expect(store.state.screen == .explainAccountRequired)

      await store.finish()
    }
  }

  @Test func `a late claim response after timeout does not re-route`() async {
    await withDependencies {
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      let store = TestStore(initialState: .init(screen: .explainAccountRequired)) {
        OnboardingFeature()
      }
      store.exhaustivity = .off

      await store.send(.trialStatusResponse(.connected(
        token: UUID(),
        childId: UUID(),
        childName: "Sally",
        subscription: .active(expiresAt: .reference + .days(300)),
      )))
      #expect(store.state.screen == .explainAccountRequired)
      #expect(store.state.trialStatus?.isConnected == true)
    }
  }
}
