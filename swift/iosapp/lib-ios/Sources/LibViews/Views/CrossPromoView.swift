import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import SwiftUI

struct CrossPromoView: View {
  @Environment(\.colorScheme) var cs
  let store: StoreOf<CrossPromoFeature>

  var body: some View {
    let campaign = self.store.campaign
    ZStack {
      Rectangle()
        .fill(Gradient(colors: [
          Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
          .clear,
        ]))
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 16) {
        Spacer()

        if let image = campaign.image, let url = URL(string: image.url) {
          AsyncImage(url: url) { phase in
            if let loaded = phase.image {
              loaded
                .resizable()
                .scaledToFit()
                .accessibilityLabel(image.description ?? "")
            }
          }
          .frame(maxWidth: .infinity)
          .frame(maxHeight: 200)
          .padding(.bottom, 24)
        }

        Text(campaign.headline)
          .font(.system(size: 26, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

        Text(campaign.body)
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100).opacity(0.85))

        BigButton(
          campaign.primaryCta.label,
          type: .button { self.store.send(.primaryBtnTapped) },
          variant: .primary,
        )
        .padding(.top, 12)

        if let secondary = campaign.secondaryCta {
          BigButton(
            secondary.label,
            type: .button { self.store.send(.secondaryBtnTapped) },
            variant: .secondary,
          )
        }

        if let tertiary = campaign.tertiaryCta {
          BigButton(
            tertiary.label,
            type: .button { self.store.send(.tertiaryBtnTapped) },
            variant: .secondary,
          )
        }
      }
      .frame(maxWidth: 500, alignment: .leading)
      .padding(30)
      .padding(.bottom, 20)
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
}
