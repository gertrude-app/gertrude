import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import LibViews
import SwiftUI

struct CrossPromoView: View {
  let store: StoreOf<CrossPromoFeature>

  var body: some View {
    ButtonScreenView(
      text: "\(self.store.campaign.headline)\n\n\(self.store.campaign.body)",
      primary: .init(
        self.store.campaign.primaryCta.label,
        animate: false,
      ) {
        self.store.send(.primaryBtnTapped)
      },
      secondary: self.store.campaign.secondaryCta.map { cta in
        .init(cta.label, animate: false) {
          self.store.send(.secondaryBtnTapped)
        }
      },
      tertiary: self.store.campaign.tertiaryCta.map { cta in
        .init(cta.label, animate: false) {
          self.store.send(.tertiaryBtnTapped)
        }
      },
      remoteImage: self.remoteImage,
      screenType: .announcement,
    )
    .interactiveDismissDisabled(!self.store.campaign.dismissable)
    .background {
      #if os(iOS)
        SharePresenter(text: self.store.share?.text) { self.store.send(.shareCompleted($0)) }
      #else
        EmptyView()
      #endif
    }
  }

  private var remoteImage: ButtonScreenView.RemoteImage? {
    let campaign = self.store.campaign
    guard let image = campaign.image else { return nil }
    return .init(url: image.url, label: image.description) { error in
      log(
        .warn,
        .setup,
        "af5b46ca",
        detail: "campaign=\(campaign.campaignId) placement=\(campaign.placement) "
          + "url=\(image.url) error=\(error)",
      )
    }
  }
}
