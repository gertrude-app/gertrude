import ComposableArchitecture
import CustomDump
import Foundation
import GertieApp
import GertieTcaFeatures
import MusicRoute
import Testing

@testable import LibTCA

@MainActor
struct CrossPromoTests {
  @Test
  func decodingDropsMalformedCampaignWithoutLosingValidCampaigns() throws {
    let json = """
    { "promos": [
      { "campaignId": "valid", "placement": "musicHome", "style": "sheet", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openUrl": { "_0": "https://gertrude.app" } } },
        "dismissable": true },
      { "campaignId": "future", "placement": "musicHome", "style": "sheet", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openDeepLink": { "_0": "x" } } },
        "dismissable": true },
      { "campaignId": "onboarding", "placement": "musicOnboarding", "style": "screen", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openAppStoreProduct": { "_0": "123" } } },
        "dismissable": false }
    ] }
    """

    let output = try JSONDecoder().decode(CrossPromos.Output.self, from: Data(json.utf8))

    expectNoDifference(output.promos.map(\.campaignId), ["valid", "onboarding"])
  }

  @Test
  func launchFetchesAndPresentsHomeCampaignForReturningUser() async {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let campaign = crossPromoCampaign(id: "home", placement: "musicHome")
    let crossPromos = CrossPromos.Output(promos: [campaign])
    let savedAt = LockIsolated<Date?>(nil)
    var state = AppFeature.State()
    state.setup.screen = .ready(childName: "Harriet")
    state.setup.resumedStoredConnection = true
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.api.crossPromos = { crossPromos }
      $0.crossPromoStorage.saveLastShownAt = { savedAt.setValue($0) }
      $0.date.now = now
    }

    await store.send(.appDidLaunch)
    await store.receive(.crossPromosReceived(crossPromos)) {
      $0.crossPromos = crossPromos
      $0.crossPromo = .init(campaign: campaign)
    }
    await store.finish()

    #expect(savedAt.value == now)
  }

  @Test
  func finishingFreshSetupPresentsCachedOnboardingCampaign() async {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let campaign = crossPromoCampaign(id: "onboarding", placement: "musicOnboarding")
    let savedAt = LockIsolated<Date?>(nil)
    var state = AppFeature.State()
    state.crossPromos = .init(promos: [campaign])
    state.setup.screen = .ready(childName: "Harriet")
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.crossPromoStorage.saveLastShownAt = { savedAt.setValue($0) }
      $0.date.now = now
    }

    await store.send(.setup(.delegate(.completed(childName: "Harriet")))) {
      $0.crossPromo = .init(campaign: campaign)
    }
    await store.finish()

    #expect(savedAt.value == now)
  }

  @Test
  func homeCampaignRespectsThrottleAndDismissals() async {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let campaign = crossPromoCampaign(id: "home", placement: "musicHome")
    var state = AppFeature.State()
    state.crossPromos = .init(promos: [campaign])
    state.setup.screen = .ready(childName: "Harriet")
    state.setup.resumedStoredConnection = true

    let throttledStore = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.crossPromoStorage.lastShownAt = { now.addingTimeInterval(-3600) }
      $0.date.now = now
    }
    await throttledStore.send(.appEnteredForeground) {
      $0.isAppActive = true
    }

    let dismissedStore = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.crossPromoStorage.dismissedCampaignIDs = { [campaign.campaignId] }
      $0.date.now = now
    }
    await dismissedStore.send(.appEnteredForeground) {
      $0.isAppActive = true
    }
  }

  @Test
  func closingCampaignPersistsDismissal() async {
    let campaign = crossPromoCampaign(id: "home", placement: "musicHome")
    let dismissedCampaignIDs = LockIsolated<Set<String>>([])
    var state = AppFeature.State()
    state.crossPromo = .init(campaign: campaign)
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.crossPromoStorage.insertDismissedCampaignID = { campaignID in
        dismissedCampaignIDs.withValue { _ = $0.insert(campaignID) }
      }
    }

    await store.send(.crossPromo(.presented(.delegate(.ctaTapped(.primary))))) {
      $0.crossPromo = nil
    }
    await store.finish()

    expectNoDifference(dismissedCampaignIDs.value, [campaign.campaignId])
  }

  @Test
  func campaignWithoutGuaranteedExitIsDropped() async {
    let campaign = CrossPromoCampaign(
      campaignId: "trapped",
      placement: "musicHome",
      style: .screen,
      headline: "Headline",
      body: "Body",
      primaryCta: .init(
        label: "Open",
        action: .openUrl("https://gertrude.app"),
      ),
      dismissable: false,
    )
    let crossPromos = CrossPromos.Output(promos: [campaign])
    var state = AppFeature.State()
    state.setup.screen = .ready(childName: "Harriet")
    state.setup.resumedStoredConnection = true
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.crossPromosReceived(crossPromos))
    await store.finish()

    #expect(store.state.crossPromos.promos.isEmpty)
    #expect(store.state.crossPromo == nil)
  }

  @Test
  func liveStoragePersistsDismissalsAndThrottleDate() {
    let suiteName = "gertrude.music.cross-promo-tests"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removePersistentDomain(forName: suiteName)
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let storage = CrossPromoStorageClient.live(userDefaults: userDefaults)

    storage.insertDismissedCampaignID("one")
    storage.insertDismissedCampaignID("two")
    storage.insertDismissedCampaignID("one")
    storage.saveLastShownAt(now)

    let reloaded = CrossPromoStorageClient.live(userDefaults: userDefaults)
    expectNoDifference(reloaded.dismissedCampaignIDs(), ["one", "two"])
    #expect(reloaded.lastShownAt() == now)
  }
}

private func crossPromoCampaign(
  id: String,
  placement: String,
) -> CrossPromoCampaign {
  .init(
    campaignId: id,
    placement: placement,
    style: .sheet,
    headline: "Headline",
    body: "Body",
    primaryCta: .init(label: "Dismiss", action: .dismiss),
    dismissable: true,
  )
}
