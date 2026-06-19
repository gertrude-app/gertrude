import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import SwiftUI

struct CrossPromoView: View {
  @Environment(\.colorScheme) var cs
  let store: StoreOf<CrossPromoFeature>

  @State private var showBg = false
  @State private var imageOffset = Vector(x: 0, y: -20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var primaryOffset = Vector(x: 0, y: 20)
  @State private var secondaryOffset = Vector(x: 0, y: 20)
  @State private var tertiaryOffset = Vector(x: 0, y: 20)

  var body: some View {
    let campaign = self.store.campaign
    ZStack {
      Rectangle()
        .fill(Gradient(colors: [
          Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
          .clear,
        ]))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Spacer()

        if let image = campaign.image, let url = URL(string: image.url) {
          AsyncImage(
            url: url,
            transaction: Transaction(animation: .smooth(duration: 0.4)),
          ) { phase in
            if let loaded = phase.image {
              loaded
                .resizable()
                .scaledToFit()
                .accessibilityLabel(image.description ?? "")
                .transition(.opacity)
            }
          }
          .frame(maxWidth: .infinity)
          .frame(height: 200)
          .padding(.bottom, 24)
          .swooshIn(
            tracking: self.$imageOffset,
            to: .zero,
            after: .zero,
            for: .milliseconds(800),
          )
        }

        Text(campaign.headline)
          .font(.system(size: 26, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .swooshIn(
            tracking: self.$textOffset,
            to: .zero,
            after: .zero,
            for: .milliseconds(800),
          )

        Text(campaign.body)
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100).opacity(0.85))
          .swooshIn(
            tracking: self.$textOffset,
            to: .zero,
            after: .zero,
            for: .milliseconds(800),
          )

        BigButton(
          campaign.primaryCta.label,
          type: .button { self.store.send(.primaryBtnTapped) },
          variant: .primary,
        )
        .padding(.top, 12)
        .swooshIn(
          tracking: self.$primaryOffset,
          to: .zero,
          after: .milliseconds(150),
          for: .milliseconds(800),
        )

        if let secondary = campaign.secondaryCta {
          BigButton(
            secondary.label,
            type: .button { self.store.send(.secondaryBtnTapped) },
            variant: .secondary,
          )
          .swooshIn(
            tracking: self.$secondaryOffset,
            to: .zero,
            after: .milliseconds(300),
            for: .milliseconds(800),
          )
        }

        if let tertiary = campaign.tertiaryCta {
          BigButton(
            tertiary.label,
            type: .button { self.store.send(.tertiaryBtnTapped) },
            variant: .secondary,
          )
          .swooshIn(
            tracking: self.$tertiaryOffset,
            to: .zero,
            after: .milliseconds(450),
            for: .milliseconds(800),
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
