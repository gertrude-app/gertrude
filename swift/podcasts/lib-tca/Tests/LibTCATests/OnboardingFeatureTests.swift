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
      let store = TestStore(initialState: .init()) { OnboardingFeature() }

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
}
