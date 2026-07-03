import ComposableArchitecture
import Dependencies
import Foundation
import GertieApp
import GertieTcaFeatures
import Testing

@MainActor struct KillSwitchFeatureTests {
  @Test func `view appeared fetches and presents a required update`() async {
    let saved = LockIsolated<KillSwitchCache?>(nil)
    await withDependencies {
      $0.date.now = referenceDate
      $0.killSwitchClient.check = { _, _ in .required(requiredDirective) }
      $0.killSwitchStorage = .init(
        load: { saved.value },
        save: { saved.setValue($0) },
      )
    } operation: {
      let store = TestStore(initialState: KillSwitchFeature.State()) {
        KillSwitchFeature(app: .blocker, deviceId: { UUID(1) })
      }

      await store.send(.viewAppeared(suggestedPresentationEnabled: true)) {
        $0.isChecking = true
      }
      await store.receive(.checkSucceeded(.required(requiredDirective))) {
        $0.isChecking = false
        $0.required = requiredDirective
      }

      #expect(saved.value?.cachedRequired == requiredDirective)
    }
  }

  @Test func `next check after suppresses launch fetch`() async {
    let called = LockIsolated(false)
    let saved = LockIsolated<KillSwitchCache?>(.init(
      nextCheckAfter: referenceDate.addingTimeInterval(60),
    ))
    await withDependencies {
      $0.date.now = referenceDate
      $0.killSwitchClient.check = { _, _ in
        called.setValue(true)
        return .required(requiredDirective)
      }
      $0.killSwitchStorage = .init(
        load: { saved.value },
        save: { saved.setValue($0) },
      )
    } operation: {
      let store = TestStore(initialState: KillSwitchFeature.State()) {
        KillSwitchFeature(app: .blocker, deviceId: { UUID(1) })
      }

      await store.send(.viewAppeared(suggestedPresentationEnabled: true))

      #expect(!called.value)
    }
  }

  @Test func `suggested updates are fetched during onboarding but presented later`() async {
    let saved = LockIsolated<KillSwitchCache?>(nil)
    await withDependencies {
      $0.date.now = referenceDate
      $0.killSwitchClient.check = { _, _ in .suggested(suggestedDirective) }
      $0.killSwitchStorage = .init(
        load: { saved.value },
        save: { saved.setValue($0) },
      )
    } operation: {
      let store = TestStore(initialState: KillSwitchFeature.State()) {
        KillSwitchFeature(app: .blocker, deviceId: { UUID(1) })
      }

      await store.send(.viewAppeared(suggestedPresentationEnabled: false)) {
        $0.canPresentSuggested = false
        $0.isChecking = true
      }
      await store.receive(.checkSucceeded(.suggested(suggestedDirective))) {
        $0.isChecking = false
      }
      await store.send(.suggestedPresentationAvailabilityChanged(true)) {
        $0.canPresentSuggested = true
        $0.suggested = suggestedDirective
      }
    }
  }

  @Test func `foregrounding re-syncs the suggested gate and presents`() async {
    let saved = LockIsolated<KillSwitchCache?>(nil)
    await withDependencies {
      $0.date.now = referenceDate
      $0.killSwitchClient.check = { _, _ in .suggested(suggestedDirective) }
      $0.killSwitchStorage = .init(
        load: { saved.value },
        save: { saved.setValue($0) },
      )
    } operation: {
      let store = TestStore(
        initialState: KillSwitchFeature.State(canPresentSuggested: false), // stale from launch
      ) {
        KillSwitchFeature(app: .blocker, deviceId: { UUID(1) })
      }

      await store.send(.appDidEnterForeground(suggestedPresentationEnabled: true)) {
        $0.canPresentSuggested = true // re-synced from the live view state
        $0.isChecking = true
      }
      await store.receive(.checkSucceeded(.suggested(suggestedDirective))) {
        $0.isChecking = false
        $0.suggested = suggestedDirective // now presents, gate is in sync
      }
    }
  }

  @Test func `a matching cached required respects the throttle`() async {
    let checked = LockIsolated(false)
    let saved = LockIsolated<KillSwitchCache?>(.init(
      nextCheckAfter: referenceDate.addingTimeInterval(60 * 60), // 1h out, suppresses the check
      cachedRequired: requiredDirective,
      cachedRequiredAppVersion: "1.0.0", // matches the test client's current build
      cachedRequiredBuild: "1",
    ))
    await withDependencies {
      $0.date.now = referenceDate
      $0.killSwitchClient.check = { _, _ in
        checked.setValue(true)
        return .required(requiredDirective)
      }
      $0.killSwitchStorage = .init(load: { saved.value }, save: { saved.setValue($0) })
    } operation: {
      let store = TestStore(initialState: KillSwitchFeature.State()) {
        KillSwitchFeature(app: .blocker, deviceId: { UUID(1) })
      }

      await store.send(.appDidEnterForeground(suggestedPresentationEnabled: true)) {
        $0.required = requiredDirective // gate restored from cache (build matches)
      }

      #expect(!checked.value) // throttle honored — no endpoint call on this foreground
    }
  }

  @Test func `a required cached under a different build is discarded`() async {
    let checked = LockIsolated(false)
    let saved = LockIsolated<KillSwitchCache?>(.init(
      nextCheckAfter: referenceDate.addingTimeInterval(60 * 60),
      cachedRequired: requiredDirective,
      cachedRequiredAppVersion: "0.9.0", // stale: predates the running build ("1.0.0")
      cachedRequiredBuild: "1",
    ))
    await withDependencies {
      $0.date.now = referenceDate
      $0.killSwitchClient.check = { _, _ in
        checked.setValue(true)
        return .current()
      }
      $0.killSwitchStorage = .init(load: { saved.value }, save: { saved.setValue($0) })
    } operation: {
      let store = TestStore(initialState: KillSwitchFeature.State()) {
        KillSwitchFeature(app: .blocker, deviceId: { UUID(1) })
      }

      await store.send(.appDidEnterForeground(suggestedPresentationEnabled: true)) {
        $0.isChecking = true // required NOT restored; forced check runs instead
      }
      await store.receive(.checkSucceeded(.current())) {
        $0.isChecking = false
      }

      #expect(saved.value?.cachedRequired == nil) // stale required cleared
      #expect(checked.value)
    }
  }

  @Test func `dismissing a suggested update stores a reminder window`() async {
    let saved = LockIsolated<KillSwitchCache?>(nil)
    await withDependencies {
      $0.date.now = referenceDate
      $0.killSwitchStorage = .init(
        load: { saved.value },
        save: { saved.setValue($0) },
      )
    } operation: {
      let store = TestStore(initialState: KillSwitchFeature.State(
        suggested: suggestedDirective,
      )) {
        KillSwitchFeature(app: .blocker, deviceId: { UUID(1) })
      }

      await store.send(.suggestedDismissButtonTapped) {
        $0.suggested = nil
      }

      #expect(saved.value?.dismissedSuggestedPolicyId == suggestedDirective.policyId)
      #expect(saved.value?.dismissedSuggestedUntil == suggestedDirective.remindAfter)
    }
  }
}

private let requiredDirective = KillSwitchDirective(
  policyId: "required",
  latestVersion: "2.0.0",
  minimumVersion: "1.5.0",
  title: "Update required",
  message: "This version is no longer supported.",
  appStoreUrl: "https://apps.apple.com/app/id123",
  nextCheckAfter: referenceDate.addingTimeInterval(60 * 60 * 12),
)

private let suggestedDirective = KillSwitchDirective(
  policyId: "suggested",
  latestVersion: "2.0.0",
  title: "Update available",
  message: "Please update soon.",
  appStoreUrl: "https://apps.apple.com/app/id123",
  remindAfter: referenceDate.addingTimeInterval(60 * 60 * 24 * 3),
  nextCheckAfter: referenceDate.addingTimeInterval(60 * 60 * 12),
)

private let referenceDate = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
