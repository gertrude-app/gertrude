import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import GertieTcaFeatures
import PodcastRoute
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct AppReducerTests {
  @Test func `reinstall with preserved db does not false onboard`() async {
    await withDependencies {
      $0.api.getTrialStatus = {
        .legacyGrandfathered(accessEndsAt: .reference, showMigrationNag: false, migrationUrl: nil)
      }
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.defaultDatabase = try! appDatabase {
        // vvv --- prior install's db survived (e.g. device restore)
        try Record.insert { [Record(id: .onboardingFinished)] }.execute($0)
      }
      $0.device.vendorId = { nil }
      $0.keychain._load = { _ in nil } // <- but keychain was wiped, no pincode
      $0.keychain._save = { _, _ in }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .onboarding(.init())
      }

      await store.send(.mode(.presented(.onboarding(.primaryBtnTapped)))) {
        // vvv --- advances normally, no crash
        $0.mode = .onboarding(.init(screen: .areYouTheParent))
      }

      await store.finish()
    }
  }

  @Test func `first launch sends 27c4f26a event after device id is established`() async {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let crossPromosFetchedAfterDeviceId = LockIsolated(false)
    let crossPromos = CrossPromos.Output(promos: [
      .init(
        campaignId: "test-campaign",
        placement: "amOnboardingParent",
        style: .screen,
        headline: "Headline",
        body: "Body",
        primaryCta: .init(label: "Open", action: .dismiss),
        dismissable: true,
      ),
    ])
    await withDependencies {
      $0.api.crossPromos = {
        crossPromosFetchedAfterDeviceId.setValue(
          keychainStore.value[KeychainClient.Key.deviceId.rawValue] != nil,
        )
        return crossPromos
      }
      $0.api.getTrialStatus = {
        .legacyGrandfathered(accessEndsAt: .reference, showMigrationNag: false, migrationUrl: nil)
      }
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.defaultDatabase = try! appDatabase()
      $0.device.vendorId = { UUID() }
      $0.keychain = dictKeychain(keychainStore)
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .onboarding(.init())
      }

      await store.receive(.receivedCrossPromos(crossPromos)) {
        $0.crossPromos = crossPromos
      }

      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.deviceId.rawValue] != nil)
      #expect(crossPromosFetchedAfterDeviceId.value)
      await Task.yield()
      #expect(loggedEventIds().contains("27c4f26a"))
    }
  }

  @Test func `foreground transition in podcasts mode presents child home promo`() async {
    let now = Date.reference
    let campaign = childHomeCampaign(id: "fm-teaser")
    await withDependencies {
      $0.api.getTrialStatus = { .legacyGrandfathered(
        accessEndsAt: .reference,
        showMigrationNag: false,
        migrationUrl: nil,
      ) }
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      initialState.crossPromos = CrossPromos.Output(promos: [campaign])
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appInForegroundChanged(false)) {
        $0.$appInForeground.withLock { $0 = false }
      }
      await store.send(.appInForegroundChanged(true)) {
        $0.$appInForeground.withLock { $0 = true }
        $0.crossPromo = .init(campaign: campaign)
      }

      await store.finish()
      #expect(dep(\.db).record(id: .amCrossPromoLastShownAt)?.updatedAt == now)
    }
  }

  @Test func `inescapable campaign is dropped at the fetch boundary and logged`() async {
    let trapped = CrossPromoCampaign(
      campaignId: "no-exit",
      placement: "amChildHome",
      style: .screen, // fullScreenCover has no swipe-to-dismiss on iOS
      headline: "Meet Gertrude Music",
      body: "Parent-curated music.",
      primaryCta: .init(label: "Check it out", action: .openUrl("https://gertrude.app/fm")),
      dismissable: false, // no dismiss-action cta and not a dismissable sheet → no way out
    )
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.receivedCrossPromos(CrossPromos.Output(promos: [trapped])))

      await store.finish()
      #expect(store.state.crossPromos.promos.isEmpty) // filtered out of state at ingestion
      #expect(store.state.crossPromo == nil) // and so never presented
      #expect(loggedEvents().contains { $0.apiId == "b9e1a7c4" })
    }
  }

  @Test func `claimed device without a pincode resumes at the passcode step`() async {
    await withDependencies {
      $0.api.getAccountStatus = {
        .init(childId: UUID(), childName: "Sally", subscription: .active(
          expiresAt: .reference + .days(300),
        ))
      }
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.defaultDatabase = try! appDatabase()
      $0.device.vendorId = { UUID() }
      $0.keychain = dictKeychain(
        LockIsolated([:]),
        installDate: .reference,
        deviceId: UUID(),
        amToken: UUID(),
      )
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      #expect(store.state.mode == .onboarding(.init(
        screen: .explainSetPasscode,
        resumedAfterClaim: true,
      )))

      await store.finish()
    }
  }

  @Test func `second foreground transition within throttle window drops`() async {
    let now = Date.reference
    let campaign = childHomeCampaign(id: "fm-teaser")
    await withDependencies {
      $0.api.getTrialStatus = { .legacyGrandfathered(
        accessEndsAt: .reference,
        showMigrationNag: false,
        migrationUrl: nil,
      ) }
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      dep(\.db).upsertRecord(id: .amCrossPromoLastShownAt, at: now - 60 * 60)
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      initialState.crossPromos = CrossPromos.Output(promos: [campaign])
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appInForegroundChanged(false)) {
        $0.$appInForeground.withLock { $0 = false }
      }
      await store.send(.appInForegroundChanged(true)) {
        $0.$appInForeground.withLock { $0 = true }
      }
      #expect(store.state.crossPromo == nil) // throttled within 72h window
      await store.finish()
    }
  }

  @Test func `dismissed campaign id never re-presents after throttle`() async {
    let now = Date.reference
    let campaign = childHomeCampaign(id: "fm-teaser")
    await withDependencies {
      $0.api.getTrialStatus = { .legacyGrandfathered(
        accessEndsAt: .reference,
        showMigrationNag: false,
        migrationUrl: nil,
      ) }
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      dep(\.db).insertCrossPromoDismissal(campaignId: "fm-teaser", at: now - 60 * 60 * 48)
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      initialState.crossPromos = CrossPromos.Output(promos: [campaign])
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appInForegroundChanged(false)) {
        $0.$appInForeground.withLock { $0 = false }
      }
      await store.send(.appInForegroundChanged(true)) {
        $0.$appInForeground.withLock { $0 = true }
      }
      #expect(store.state.crossPromo == nil) // dismissed campaign id filtered out
      await store.finish()
    }
  }

  @Test func `receivedCrossPromos in podcasts mode presents child home on cold launch`() async {
    let now = Date.reference
    let campaign = childHomeCampaign(id: "fm-teaser")
    let envelope = CrossPromos.Output(promos: [campaign])
    await withDependencies {
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)

      await store.send(.receivedCrossPromos(envelope)) {
        $0.crossPromos = envelope
        $0.crossPromo = .init(campaign: campaign)
      }
      await store.finish()
    }
  }

  @Test func `receivedCrossPromos during onboarding does not present child home`() async {
    let envelope = CrossPromos.Output(promos: [childHomeCampaign(id: "fm-teaser")])
    await withDependencies {
      $0.defaultDatabase = try! appDatabase()
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .onboarding(.init())
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)

      await store.send(.receivedCrossPromos(envelope)) {
        $0.crossPromos = envelope
      }
      await store.finish()
    }
  }

  @Test func `dismissing cross promo persists campaign id to dismissals table`() async {
    let now = Date.reference
    let campaign = childHomeCampaign(id: "fm-teaser")
    await withDependencies {
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      initialState.crossPromo = .init(campaign: campaign)
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)

      await store.send(.crossPromo(.presented(.delegate(.dismissed)))) {
        $0.crossPromo = nil
      }
      await store.finish()

      #expect(dep(\.db).dismissedCrossPromoIds().contains("fm-teaser"))
    }
  }

  @Test func `swipe dismissing cross promo persists campaign id to dismissals table`() async {
    let now = Date.reference
    let campaign = childHomeCampaign(id: "fm-teaser")
    await withDependencies {
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      initialState.crossPromo = .init(campaign: campaign)
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)

      await store.send(.crossPromo(.dismiss)) { // swipe-to-dismiss, not a button tap
        $0.crossPromo = nil
      }
      await store.finish()

      #expect(dep(\.db).dismissedCrossPromoIds().contains("fm-teaser"))
    }
  }

  @Test func `presenting a promo logs an impression with campaign, variant, placement`() async {
    let now = Date.reference
    let campaign = CrossPromoCampaign(
      campaignId: "fm-teaser",
      variant: "B", // the A/B arm — must survive into the logged event
      placement: "amChildHome",
      style: .sheet,
      headline: "Meet Gertrude Music",
      body: "Parent-curated music.",
      primaryCta: .init(label: "Check it out", action: .dismiss),
      dismissable: true,
    )
    await withDependencies {
      $0.api.getTrialStatus = { .legacyGrandfathered(
        accessEndsAt: .reference,
        showMigrationNag: false,
        migrationUrl: nil,
      ) }
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]))
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      initialState.crossPromos = CrossPromos.Output(promos: [campaign])
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appInForegroundChanged(false)) {
        $0.$appInForeground.withLock { $0 = false }
      }
      await store.send(.appInForegroundChanged(true)) {
        $0.$appInForeground.withLock { $0 = true }
        $0.crossPromo = .init(campaign: campaign)
      }
      await store.finish()

      let impression = loggedEvents().first { $0.apiId == "fa1c7e93" }
      #expect(impression?.detail == "campaign=fm-teaser variant=B placement=amChildHome")
    }
  }

  @Test func `tapping a cta logs a cta event with its slot and action, and closes`() async {
    let now = Date.reference
    let campaign = CrossPromoCampaign(
      campaignId: "fm-teaser",
      placement: "amChildHome",
      style: .sheet,
      headline: "Meet Gertrude Music",
      body: "Parent-curated music.",
      primaryCta: .init(label: "Check it out", action: .openUrl("https://gertrude.app")),
      secondaryCta: .init(label: "No thanks", action: .dismiss),
      dismissable: true,
    )
    await withDependencies {
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase()
    } operation: {
      var initialState = AppReducer.State()
      initialState.mode = .podcasts(.init())
      initialState.crossPromo = .init(campaign: campaign)
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)

      await store.send(.crossPromo(.presented(.delegate(.ctaTapped(.primary))))) {
        $0.crossPromo = nil
      }
      await store.finish()

      let cta = loggedEvents().first { $0.apiId == "b62d4a8f" }
      #expect(cta?
        .detail ==
        "campaign=fm-teaser variant=- placement=amChildHome slot=primary action=open-url")
      #expect(dep(\.db).dismissedCrossPromoIds().contains("fm-teaser")) // engaged → don't re-show
    }
  }

  @Test func `finishing onboarding does not re-present a dismissed campaign`() async {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let campaign = CrossPromoCampaign(
      campaignId: "already-dismissed",
      placement: "amOnboardingParent",
      style: .screen,
      headline: "Headline",
      body: "Body",
      primaryCta: .init(label: "Open", action: .dismiss),
      dismissable: true,
    )
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain._load = { key in keychainStore.value[key.rawValue] }
      $0.keychain._save = { key, data in keychainStore.withValue { $0[key.rawValue] = data } }
    } operation: {
      dep(\.db).insertCrossPromoDismissal(campaignId: "already-dismissed", at: .reference)
      var initialState = AppReducer.State()
      initialState.crossPromos = CrossPromos.Output(promos: [campaign])
      initialState.mode = .onboarding(.init(screen: .strongPasscode))
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.mode(.presented(.onboarding(.finished(1234))))) {
        $0.mode = .podcasts(.init())
      }

      await store.finish()
      #expect(store.state.crossPromo == nil) // dismissed onboarding campaign not re-shown
    }
  }

  @Test func `finishing onboarding saves pin and presents cached cross promo`() async {
    let keychainStore = LockIsolated<[String: Data]>([:])
    let crossPromos = CrossPromos.Output(promos: [
      .init(
        campaignId: "test-campaign",
        placement: "amOnboardingParent",
        style: .screen,
        headline: "Headline",
        body: "Body",
        primaryCta: .init(label: "Open", action: .dismiss),
        dismissable: true,
      ),
    ])
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain._load = { key in keychainStore.value[key.rawValue] }
      $0.keychain._save = { key, data in keychainStore.withValue { $0[key.rawValue] = data } }
    } operation: {
      var initialState = AppReducer.State()
      initialState.crossPromos = crossPromos
      initialState.mode = .onboarding(.init(screen: .strongPasscode))
      let store = TestStore(initialState: initialState, reducer: AppReducer.init)

      await store.send(.mode(.presented(.onboarding(.finished(1234))))) {
        $0.mode = .podcasts(.init())
        $0.crossPromo = .init(campaign: crossPromos.promos[0])
      }

      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.pincode.rawValue] == "1234".data(using: .utf8))
      #expect(dep(\.db).record(id: .onboardingFinished) != nil)
      // onboarding promo stamps the shared clock, so child home is throttled right after
      #expect(dep(\.db).record(id: .amCrossPromoLastShownAt) != nil)
    }
  }

  @Test func `pin set after a mid-claim relaunch logs the detection event`() async {
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]), installDate: .reference, deviceId: UUID())
    } operation: {
      let store = TestStore(
        initialState: .init(mode: .onboarding(.init(
          screen: .explainSetPasscode,
          resumedAfterClaim: true,
        ))),
        reducer: AppReducer.init,
      )
      store.exhaustivity = .off

      await store.send(.mode(.presented(.onboarding(.finished(123_456)))))
      #expect(store.state.mode == .podcasts(.init()))

      await store.finish()
      await Task.yield()
      #expect(loggedEventIds().contains("ba182b20"))
      #expect(loggedEventIds().contains("c3e9a1f4"))
    }
  }

  @Test func `normal onboarding finish does not log the detection event`() async {
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]), installDate: .reference, deviceId: UUID())
    } operation: {
      let store = TestStore(
        initialState: .init(mode: .onboarding(.init(screen: .strongPasscode))),
        reducer: AppReducer.init,
      )
      store.exhaustivity = .off

      await store.send(.mode(.presented(.onboarding(.finished(123_456)))))
      await store.finish()
      await Task.yield()
      #expect(loggedEventIds().contains("ba182b20"))
      #expect(!loggedEventIds().contains("c3e9a1f4"))
    }
  }

  @Test func `foregrounding silently flips a skip user to active once claimed`() async {
    let keychainStore = LockIsolated<[String: Data]>([:])
    await withDependencies {
      $0.api.getTrialStatus = {
        .connected(
          token: UUID(),
          childId: UUID(),
          childName: "Sally",
          subscription: .active(expiresAt: .reference + .days(300)),
        )
      }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(
        keychainStore,
        pincode: 111_111, // ← has a PIN (went through PIN setup)
        installDate: .reference,
        deviceId: UUID(),
        // ← no amToken passed → NOT claimed (they skipped connecting an account)
      )
    } operation: {
      _ = try? CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(20))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appInForegroundChanged(true))
      await store.finish()

      #expect(dep(\.db).subscription().status == .active)
      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] != nil)
      #expect(store.state.alert == nil)
    }
  }
}

private func childHomeCampaign(id: String) -> CrossPromoCampaign {
  CrossPromoCampaign(
    campaignId: id,
    placement: "amChildHome",
    style: .sheet,
    headline: "Meet Gertrude Music",
    body: "Parent-curated music.",
    primaryCta: .init(label: "Check it out", action: .dismiss),
    secondaryCta: .init(label: "No thanks", action: .dismiss),
    dismissable: true,
  )
}
