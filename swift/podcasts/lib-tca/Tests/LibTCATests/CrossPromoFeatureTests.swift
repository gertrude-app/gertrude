import ComposableArchitecture
import Dependencies
import Foundation
import PodcastRoute
import Testing

@testable import LibTCA

@MainActor struct CrossPromoFeatureTests {
  @Test func `primary cta opens url and reports the tap`() async {
    let opened = LockIsolated<URL?>(nil)
    await withDependencies {
      $0.openURL = OpenURLEffect { url in
        opened.setValue(url)
        return true
      }
    } operation: {
      let store = TestStore(
        initialState: CrossPromoFeature
          .State(campaign: campaign(.openUrl("https://gertrude.app/fm"))),
      ) { CrossPromoFeature() }

      await store.send(.primaryBtnTapped)
      await store.receive(.delegate(.ctaTapped(.primary)))

      #expect(opened.value == URL(string: "https://gertrude.app/fm"))
    }
  }

  @Test func `primary cta does not report tap when the open fails`() async {
    await withDependencies {
      $0.openURL = OpenURLEffect { _ in false } // system declines to open
    } operation: {
      let store = TestStore(
        initialState: CrossPromoFeature
          .State(campaign: campaign(.openUrl("https://gertrude.app/fm"))),
      ) { CrossPromoFeature() }

      await store.send(.primaryBtnTapped) // no .ctaTapped → campaign is not burned
    }
  }

  @Test func `primary cta with a dismiss action reports a dismissal`() async {
    let store = TestStore(
      initialState: CrossPromoFeature.State(campaign: campaign(.dismiss)),
    ) { CrossPromoFeature() }

    await store.send(.primaryBtnTapped)
    await store.receive(.delegate(.dismissed))
  }

  @Test func `secondary cta performs its own action and reports its slot`() async {
    let opened = LockIsolated<URL?>(nil)
    await withDependencies {
      $0.openURL = OpenURLEffect { url in opened.setValue(url)
        return true
      }
    } operation: {
      let store = TestStore(
        initialState: CrossPromoFeature.State(
          campaign: campaign(.dismiss, secondary: .openAppStoreProduct("6736368820")),
        ),
      ) { CrossPromoFeature() }

      await store.send(.secondaryBtnTapped)
      await store.receive(.delegate(.ctaTapped(.secondary)))

      #expect(opened.value == URL(string: "https://apps.apple.com/app/id6736368820"))
    }
  }

  @Test func `tertiary cta performs its own action`() async {
    let store = TestStore(
      initialState: CrossPromoFeature.State(
        campaign: campaign(.openUrl("https://gertrude.app"), tertiary: .dismiss),
      ),
    ) { CrossPromoFeature() }

    await store.send(.tertiaryBtnTapped)
    await store.receive(.delegate(.dismissed))
  }

  @Test func `share primary opens the share sheet`() async {
    let store = TestStore(
      initialState: CrossPromoFeature.State(campaign: campaign(.share("Ask a parent for FM"))),
    ) { CrossPromoFeature() }

    await store.send(.primaryBtnTapped) {
      $0.share = .init(text: "Ask a parent for FM", slot: .primary)
    }
  }

  @Test func `completing a share reports the tap and closes`() async {
    let store = TestStore(
      initialState: CrossPromoFeature.State(
        campaign: campaign(.share("Ask a parent for FM")),
        share: .init(text: "Ask a parent for FM", slot: .primary),
      ),
    ) { CrossPromoFeature() }

    await store.send(.shareCompleted(true)) {
      $0.share = nil
    }
    await store.receive(.delegate(.ctaTapped(.primary)))
  }

  @Test func `cancelling a share leaves the promo open`() async {
    let store = TestStore(
      initialState: CrossPromoFeature.State(
        campaign: campaign(.share("Ask a parent for FM")),
        share: .init(text: "Ask a parent for FM", slot: .primary),
      ),
    ) { CrossPromoFeature() }

    await store.send(.shareCompleted(false)) {
      $0.share = nil // cleared, but no .ctaTapped → root keeps the promo up
    }
  }
}

private func campaign(
  _ primary: CrossPromoAction,
  secondary: CrossPromoAction? = nil,
  tertiary: CrossPromoAction? = nil,
) -> CrossPromoCampaign {
  CrossPromoCampaign(
    campaignId: "fm-launch",
    placement: .amOnboardingParent,
    style: .sheet,
    headline: "Meet Gertrude FM",
    body: "Parent-curated music.",
    primaryCta: .init(label: "Check it out", action: primary),
    secondaryCta: secondary.map { .init(label: "Secondary", action: $0) },
    tertiaryCta: tertiary.map { .init(label: "Tertiary", action: $0) },
    dismissable: true,
  )
}
