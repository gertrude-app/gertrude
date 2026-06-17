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
      remoteImage: self.store.campaign.image.map { .init(url: $0.url, label: $0.description) },
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
}
