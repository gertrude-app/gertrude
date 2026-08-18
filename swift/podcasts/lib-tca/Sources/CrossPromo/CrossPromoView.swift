import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import GertieUI
import LibViews
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
          .setup,
          "af5b46ca",
          detail: "campaign=\(campaign.campaignId) placement=\(campaign.placement) "
            + "url=\(image.url) error=\(error)",
        )
      },
    )
  }
}
