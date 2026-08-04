import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import GertieUI
import LibClients
import SwiftUI

struct CrossPromoView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ScaledMetric(relativeTo: .title) private var titleScale = 1.0
  @ScaledMetric(relativeTo: .body) private var bodyScale = 1.0

  let store: StoreOf<CrossPromoFeature>

  var body: some View {
    GeometryReader { proxy in
      let isCompact = proxy.size.height <= 700 || self.dynamicTypeSize.isAccessibilitySize

      ScrollView {
        self.content(
          campaign: self.store.campaign,
          metrics: isCompact ? .compact : .regular,
        )
        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
      }
      .scrollBounceBehavior(.basedOnSize)
      .scrollIndicators(.hidden)
    }
    .gertieScreenBackground()
    .interactiveDismissDisabled(!self.store.campaign.dismissable)
    .background {
      #if os(iOS)
        SharePresenter(text: self.store.share?.text) { self.store.send(.shareCompleted($0)) }
      #else
        EmptyView()
      #endif
    }
  }

  private func content(
    campaign: CrossPromoCampaign,
    metrics: Metrics,
  ) -> some View {
    VStack(alignment: .leading, spacing: metrics.spacing) {
      Spacer(minLength: metrics.isCompact ? 0 : nil)

      if let image = campaign.image {
        CrossPromoImage(
          url: image.url,
          label: image.description,
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
        .frame(maxWidth: .infinity)
        .frame(height: metrics.imageHeight)
        .padding(.bottom, metrics.imagePadBottom)
        .swooshIn(fromYOffset: -20)
      }

      Text(campaign.headline)
        .font(.system(size: metrics.headlineSize * self.titleScale, weight: .bold))
        .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
        .fixedSize(horizontal: false, vertical: true)
        .swooshIn(fromYOffset: 20)

      Text(campaign.body)
        .font(.system(size: metrics.bodySize * self.bodyScale, weight: .medium))
        .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100).opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
        .swooshIn(fromYOffset: 20)

      Button(campaign.primaryCta.label) {
        self.store.send(.primaryBtnTapped)
      }
      .buttonStyle(.gertiePrimary)
      .padding(.top, metrics.buttonPadTop)
      .swooshIn(fromYOffset: 20, after: .milliseconds(150))

      if let secondary = campaign.secondaryCta {
        Button(secondary.label) {
          self.store.send(.secondaryBtnTapped)
        }
        .buttonStyle(.gertieSecondary)
        .swooshIn(fromYOffset: 20, after: .milliseconds(300))
      }

      if let tertiary = campaign.tertiaryCta {
        Button(tertiary.label) {
          self.store.send(.tertiaryBtnTapped)
        }
        .buttonStyle(.gertieSecondary)
        .swooshIn(fromYOffset: 20, after: .milliseconds(450))
      }
    }
    .frame(maxWidth: 500, alignment: .leading)
    .padding(metrics.insets)
  }

  private struct Metrics {
    let isCompact: Bool
    let spacing: CGFloat
    let headlineSize: CGFloat
    let bodySize: CGFloat
    let imageHeight: CGFloat
    let imagePadBottom: CGFloat
    let buttonPadTop: CGFloat
    let insets: EdgeInsets

    static let regular = Self(
      isCompact: false,
      spacing: 16,
      headlineSize: 26,
      bodySize: 17,
      imageHeight: 200,
      imagePadBottom: 24,
      buttonPadTop: 12,
      insets: EdgeInsets(top: 30, leading: 30, bottom: 50, trailing: 30),
    )

    static let compact = Self(
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
}

private struct CrossPromoImage: View {
  let url: String
  let label: String?
  let onLoadFailure: (@MainActor @Sendable (any Error) -> Void)?

  var body: some View {
    if let url = URL(string: self.url) {
      RetryingAsyncImage(
        url: url,
        animation: .smooth(duration: 0.4),
        onFailure: self.onLoadFailure,
      ) { image in
        image
          .resizable()
          .scaledToFit()
          .accessibilityLabel(Text(verbatim: self.label ?? ""))
          .transition(.opacity)
      } placeholder: {
        EmptyView()
      }
    }
  }
}
