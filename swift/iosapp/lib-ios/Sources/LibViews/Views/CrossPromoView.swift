import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import GertieUI
import LibClients
import SwiftUI

struct CrossPromoView: View {
  let store: StoreOf<CrossPromoFeature>

  var body: some View {
    let campaign = self.store.campaign
    GertieCrossPromoScreen(
      headline: campaign.headline,
      body: campaign.body,
      image: self.remoteImage,
      primaryAction: .button(campaign.primaryCta.label) {
        self.store.send(.primaryBtnTapped)
      },
      secondaryAction: campaign.secondaryCta.map { cta in
        .button(cta.label) {
          self.store.send(.secondaryBtnTapped)
        }
      },
      tertiaryAction: campaign.tertiaryCta.map { cta in
        .button(cta.label) {
          self.store.send(.tertiaryBtnTapped)
        }
      },
    )
    .interactiveDismissDisabled(!campaign.dismissable)
    .background {
      #if os(iOS)
        SharePresenter(text: self.store.share?.text) { self.store.send(.shareCompleted($0)) }
      #else
        EmptyView()
      #endif
    }
  }

  private var remoteImage: GertieCrossPromoScreen.RemoteImage? {
    let campaign = self.store.campaign
    guard let image = campaign.image, let url = URL(string: image.url) else { return nil }
    return .init(
      url: url,
      accessibilityLabel: image.description,
      onLoadFailure: { error in
        log(
          .warn,
          "670a86df",
          detail: "cross promo image load failed"
            + " campaign=\(campaign.campaignId) placement=\(campaign.placement)"
            + " url=\(image.url) error=\(error)",
        )
      },
    )
  }
}

#Preview("Regular") {
  CrossPromoView(
    store: .init(initialState: .init(campaign: .preview)) {
      EmptyReducer()
    },
  )
}

#Preview("Primary action only") {
  CrossPromoView(
    store: .init(initialState: .init(campaign: .primaryActionPreview)) {
      EmptyReducer()
    },
  )
}

#Preview("Compact height", traits: .fixedLayout(width: 375, height: 667)) {
  CrossPromoView(
    store: .init(initialState: .init(campaign: .preview)) {
      EmptyReducer()
    },
  )
}

#Preview("Accessibility text") {
  CrossPromoView(
    store: .init(initialState: .init(campaign: .preview)) {
      EmptyReducer()
    },
  )
  .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
  CrossPromoView(
    store: .init(initialState: .init(campaign: .preview)) {
      EmptyReducer()
    },
  )
  .preferredColorScheme(.dark)
}

private extension CrossPromoCampaign {
  static let preview = Self(
    campaignId: "ios-blocker-onboarding-gertrude-am-v1",
    placement: "iosBlockerOnboarding",
    style: .screen,
    headline: "Kid-safe podcasts too!",
    body: "Gertrude Podcasts is a podcast player app where parents choose the shows and kids listen independently. Searching and subscribing to podcasts is locked behind a PIN code.",
    image: .init(
      url: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-am-icon-512.png",
      description: "Gertrude Podcasts app icon",
    ),
    primaryCta: .init(
      label: "Get Gertrude Podcasts",
      action: .openAppStoreProduct("6753187429"),
    ),
    secondaryCta: .init(
      label: "Send a link ↗",
      action: .share("https://gertrude.app/blog/safe-podcast-app-for-kids"),
    ),
    tertiaryCta: .init(label: "No thanks", action: .dismiss),
    dismissable: false,
  )

  static let primaryActionPreview = Self(
    campaignId: "ios-blocker-primary-action-preview",
    placement: "iosBlockerOnboarding",
    style: .sheet,
    headline: "A safer way to listen",
    body: "Parents choose the shows, and kids listen independently.",
    primaryCta: .init(
      label: "Learn more",
      action: .openUrl("https://gertrude.app"),
    ),
    dismissable: true,
  )
}
