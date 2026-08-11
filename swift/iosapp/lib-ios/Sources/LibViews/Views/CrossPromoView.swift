import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import LibClients
import SwiftUI

struct CrossPromoView: View {
  @Environment(\.colorScheme) var cs
  @ScaledMetric(relativeTo: .title) private var titleScale = 1.0
  @ScaledMetric(relativeTo: .body) private var bodyScale = 1.0

  let store: StoreOf<CrossPromoFeature>

  @State private var imageOffset = Vector(x: 0, y: -20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var primaryOffset = Vector(x: 0, y: 20)
  @State private var secondaryOffset = Vector(x: 0, y: 20)
  @State private var tertiaryOffset = Vector(x: 0, y: 20)

  private struct Metrics {
    var isCompact: Bool
    var spacing: CGFloat
    var headlineSize: CGFloat
    var bodySize: CGFloat
    var imageHeight: CGFloat
    var imagePadBottom: CGFloat
    var buttonPadTop: CGFloat
    var insets: EdgeInsets

    static let regular = Metrics(
      isCompact: false,
      spacing: 16,
      headlineSize: 26,
      bodySize: 17,
      imageHeight: 200,
      imagePadBottom: 24,
      buttonPadTop: 12,
      insets: EdgeInsets(top: 30, leading: 30, bottom: 50, trailing: 30),
    )

    static let compact = Metrics(
      isCompact: true,
      spacing: 12,
      headlineSize: 24,
      bodySize: 16,
      imageHeight: 140,
      imagePadBottom: 8,
      buttonPadTop: 8,
      insets: EdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22),
    )
  }

  var body: some View {
    let campaign = self.store.campaign
    AdaptiveScreen { isCompact in
      self.content(campaign: campaign, m: isCompact ? .compact : .regular)
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

  private func content(campaign: CrossPromoCampaign, m: Metrics) -> some View {
    VStack(alignment: .leading, spacing: m.spacing) {
      Spacer(minLength: m.isCompact ? 0 : nil)

      if let image = campaign.image, let url = URL(string: image.url) {
        RetryingAsyncImage(
          url: url,
          animation: .smooth(duration: 0.4),
          onFailure: { error in
            log(
              .warn,
              "670a86df",
              detail: "cross promo image load failed"
                + " campaign=\(campaign.campaignId) placement=\(campaign.placement)"
                + " url=\(image.url) error=\(error)",
            )
          },
        ) { loaded in
          loaded
            .resizable()
            .scaledToFit()
            .accessibilityLabel(image.description ?? "")
            .transition(.opacity)
        } placeholder: {
          EmptyView()
        }
        .frame(maxWidth: .infinity)
        .frame(height: m.imageHeight)
        .padding(.bottom, m.imagePadBottom)
        .swooshIn(
          tracking: self.$imageOffset,
          to: .zero,
          after: .zero,
          for: .milliseconds(800),
        )
      }

      Text(campaign.headline)
        .font(.system(size: m.headlineSize * self.titleScale, weight: .bold))
        .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
        .fixedSize(horizontal: false, vertical: true)
        .swooshIn(
          tracking: self.$textOffset,
          to: .zero,
          after: .zero,
          for: .milliseconds(800),
        )

      Text(campaign.body)
        .font(.system(size: m.bodySize * self.bodyScale, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100).opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
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
      .padding(.top, m.buttonPadTop)
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
    .padding(m.insets)
  }
}
