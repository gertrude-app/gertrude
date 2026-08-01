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
    GertieActionScreen(
      message: "\(campaign.headline)\n\n\(campaign.body)",
      icon: .announcement,
      actions: self.actions,
      supplementPlacement: .beforeMessage,
    ) {
      if let image = campaign.image {
        CrossPromoImage(
          url: image.url,
          label: image.description,
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
    .interactiveDismissDisabled(!campaign.dismissable)
    .background {
      #if os(iOS)
        SharePresenter(text: self.store.share?.text) { self.store.send(.shareCompleted($0)) }
      #else
        EmptyView()
      #endif
    }
  }

  private var actions: [GertieScreenAction] {
    var actions: [GertieScreenAction] = [
      .button(self.store.campaign.primaryCta.label) {
        self.store.send(.primaryBtnTapped)
      },
    ]

    if let cta = self.store.campaign.secondaryCta {
      actions.append(.button(cta.label) {
        self.store.send(.secondaryBtnTapped)
      })
    }

    if let cta = self.store.campaign.tertiaryCta {
      actions.append(.button(cta.label) {
        self.store.send(.tertiaryBtnTapped)
      })
    }

    return actions
  }
}
