import Foundation
import SwiftUI

public struct GertieCrossPromoScreen: View {
  public struct Action {
    fileprivate let title: String
    fileprivate let callback: @MainActor () -> Void

    public static func button(
      _ title: String,
      action: @MainActor @escaping () -> Void,
    ) -> Self {
      Self(title: title, callback: action)
    }
  }

  public struct RemoteImage: Sendable {
    fileprivate let url: URL
    fileprivate let accessibilityLabel: String?
    fileprivate let onLoadFailure: (@MainActor @Sendable (any Error) -> Void)?

    public init(
      url: URL,
      accessibilityLabel: String? = nil,
      onLoadFailure: (@MainActor @Sendable (any Error) -> Void)? = nil,
    ) {
      self.url = url
      self.accessibilityLabel = accessibilityLabel
      self.onLoadFailure = onLoadFailure
    }
  }

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ScaledMetric(relativeTo: .title) private var titleScale = 1.0
  @ScaledMetric(relativeTo: .body) private var bodyScale = 1.0

  private let headline: String
  private let bodyText: String
  private let image: RemoteImage?
  private let primaryAction: Action
  private let secondaryAction: Action?
  private let tertiaryAction: Action?

  public init(
    headline: String,
    body: String,
    image: RemoteImage? = nil,
    primaryAction: Action,
    secondaryAction: Action? = nil,
    tertiaryAction: Action? = nil,
  ) {
    self.headline = headline
    self.bodyText = body
    self.image = image
    self.primaryAction = primaryAction
    self.secondaryAction = secondaryAction
    self.tertiaryAction = tertiaryAction
  }

  public var body: some View {
    GeometryReader { proxy in
      let metrics = proxy.size.height <= 700 || self.dynamicTypeSize.isAccessibilitySize
        ? Metrics.compact
        : Metrics.regular

      ScrollView {
        VStack(alignment: .leading, spacing: metrics.spacing) {
          Spacer(minLength: metrics.isCompact ? 0 : nil)

          GertieCrossPromoVisual(
            image: self.image,
            imageHeight: metrics.imageHeight,
          )
          .padding(.bottom, metrics.imagePadBottom)

          Text(verbatim: self.headline)
            .font(.system(size: metrics.headlineSize * self.titleScale, weight: .bold))
            .foregroundStyle(
              Color(self.colorScheme, light: .violet950, dark: .violet100),
            )
            .fixedSize(horizontal: false, vertical: true)
            .swooshIn(fromYOffset: 20)

          Text(verbatim: self.bodyText)
            .font(.system(size: metrics.bodySize * self.bodyScale, weight: .medium))
            .foregroundStyle(
              Color(self.colorScheme, light: .violet950, dark: .violet100).opacity(0.85),
            )
            .fixedSize(horizontal: false, vertical: true)
            .swooshIn(fromYOffset: 20)

          Button(self.primaryAction.title, action: self.primaryAction.callback)
            .buttonStyle(.gertiePrimary)
            .accessibilityIdentifier("btn-primary")
            .padding(.top, metrics.buttonPadTop)
            .swooshIn(fromYOffset: 20, after: .milliseconds(150))

          if let secondaryAction = self.secondaryAction {
            Button(secondaryAction.title, action: secondaryAction.callback)
              .buttonStyle(.gertieSecondary)
              .accessibilityIdentifier("btn-secondary")
              .swooshIn(fromYOffset: 20, after: .milliseconds(300))
          }

          if let tertiaryAction = self.tertiaryAction {
            Button(tertiaryAction.title, action: tertiaryAction.callback)
              .buttonStyle(.gertieSecondary)
              .accessibilityIdentifier("onboarding-tertiary-button")
              .swooshIn(fromYOffset: 20, after: .milliseconds(450))
          }
        }
        .frame(maxWidth: 500, alignment: .leading)
        .padding(metrics.insets)
        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
      }
      .scrollBounceBehavior(.basedOnSize)
      .scrollIndicators(.hidden)
    }
    .gertieScreenBackground()
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
      headlineSize: 24,
      bodySize: 17,
      imageHeight: 200,
      imagePadBottom: 24,
      buttonPadTop: 12,
      insets: EdgeInsets(top: 30, leading: 30, bottom: 50, trailing: 30),
    )

    static let compact = Self(
      isCompact: true,
      spacing: 12,
      headlineSize: 22,
      bodySize: 16,
      imageHeight: 140,
      imagePadBottom: 8,
      buttonPadTop: 8,
      insets: EdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22),
    )
  }
}

private struct GertieCrossPromoVisual: View {
  let image: GertieCrossPromoScreen.RemoteImage?
  let imageHeight: CGFloat

  var body: some View {
    Group {
      if let image = self.image {
        RetryingAsyncImage(
          url: image.url,
          animation: .smooth(duration: 0.4),
          onFailure: image.onLoadFailure,
        ) { loadedImage in
          loadedImage
            .resizable()
            .scaledToFit()
            .accessibilityLabel(Text(verbatim: image.accessibilityLabel ?? ""))
            .transition(.opacity)
        } placeholder: {
          ProgressView()
        } failure: {
          GertieCrossPromoFallback()
        }
        .id(image.url)
        .frame(maxWidth: .infinity)
        .frame(height: self.imageHeight)
        .swooshIn(fromYOffset: -20)
      } else {
        GertieCrossPromoFallback()
      }
    }
  }
}

private struct GertieCrossPromoFallback: View {
  @Environment(\.colorScheme) private var colorScheme
  @ScaledMetric(relativeTo: .title) private var iconSize = 40.0

  var body: some View {
    Image(systemName: "sparkles")
      .font(.system(size: self.iconSize, weight: .regular))
      .foregroundStyle(
        Color(self.colorScheme, light: .violet500, dark: .violet400),
      )
      .accessibilityHidden(true)
      .frame(maxWidth: .infinity, alignment: .center)
      .swooshIn(fromYOffset: -20)
  }
}

#Preview("Regular") {
  GertieCrossPromoScreen(
    headline: "Introducing Gertrude Music",
    body: "You choose the music. They get a delightful listening app that shows only what you’ve approved—no search, feeds, chat, or recommendations.",
    image: .init(
      url: URL(
        string: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      )!,
      accessibilityLabel: "Gertrude Music icon over a blurred album library",
    ),
    primaryAction: .button("Get Gertrude Music") {},
    secondaryAction: .button("Send a link ↗") {},
    tertiaryAction: .button("No thanks") {},
  )
}

#Preview("No image") {
  GertieCrossPromoScreen(
    headline: "A safer way to listen",
    body: "Parents choose the shows, and kids listen independently.",
    primaryAction: .button("Learn more") {},
  )
}

#Preview("Compact height", traits: .fixedLayout(width: 375, height: 667)) {
  GertieCrossPromoScreen(
    headline: "Introducing Gertrude Music",
    body: "You choose the music. They get a delightful listening app that shows only what you’ve approved—no search, feeds, chat, or recommendations.",
    image: .init(
      url: URL(
        string: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      )!,
      accessibilityLabel: "Gertrude Music icon over a blurred album library",
    ),
    primaryAction: .button("Get Gertrude Music") {},
    secondaryAction: .button("Send a link ↗") {},
    tertiaryAction: .button("No thanks") {},
  )
}

#Preview("Accessibility text") {
  GertieCrossPromoScreen(
    headline: "Introducing Gertrude Music",
    body: "You choose the music. They get a delightful listening app that shows only what you’ve approved—no search, feeds, chat, or recommendations.",
    image: .init(
      url: URL(
        string: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      )!,
      accessibilityLabel: "Gertrude Music icon over a blurred album library",
    ),
    primaryAction: .button("Get Gertrude Music") {},
    secondaryAction: .button("Send a link ↗") {},
    tertiaryAction: .button("No thanks") {},
  )
  .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
  GertieCrossPromoScreen(
    headline: "Introducing Gertrude Music",
    body: "You choose the music. They get a delightful listening app that shows only what you’ve approved—no search, feeds, chat, or recommendations.",
    image: .init(
      url: URL(
        string: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-music-v1.webp",
      )!,
      accessibilityLabel: "Gertrude Music icon over a blurred album library",
    ),
    primaryAction: .button("Get Gertrude Music") {},
    secondaryAction: .button("Send a link ↗") {},
    tertiaryAction: .button("No thanks") {},
  )
  .preferredColorScheme(.dark)
}
