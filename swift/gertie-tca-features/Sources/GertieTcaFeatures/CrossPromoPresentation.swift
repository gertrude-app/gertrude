import ComposableArchitecture
import GertieApp
import GertieUI
import SwiftUI

public typealias CrossPromoImageLoadFailureHandler = @MainActor @Sendable (
  CrossPromoCampaign,
  CrossPromoImage,
  any Error,
) -> Void

public struct CrossPromoFeatureView: View {
  private let onImageLoadFailure: CrossPromoImageLoadFailureHandler
  private let store: StoreOf<CrossPromoFeature>

  public init(
    store: StoreOf<CrossPromoFeature>,
    onImageLoadFailure: @escaping CrossPromoImageLoadFailureHandler = { _, _, _ in },
  ) {
    self.store = store
    self.onImageLoadFailure = onImageLoadFailure
  }

  public var body: some View {
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
    let onImageLoadFailure = self.onImageLoadFailure
    return .init(
      url: url,
      accessibilityLabel: image.description,
      onLoadFailure: { error in
        onImageLoadFailure(campaign, image, error)
      },
    )
  }
}

private struct CrossPromoPresentationModifier: ViewModifier {
  @Binding private var store: StoreOf<CrossPromoFeature>?
  private let onImageLoadFailure: CrossPromoImageLoadFailureHandler

  init(
    store: Binding<StoreOf<CrossPromoFeature>?>,
    onImageLoadFailure: @escaping CrossPromoImageLoadFailureHandler,
  ) {
    self._store = store
    self.onImageLoadFailure = onImageLoadFailure
  }

  func body(content: Content) -> some View {
    content
      .sheet(item: self.$store.sheetPresentation) { store in
        CrossPromoFeatureView(
          store: store,
          onImageLoadFailure: self.onImageLoadFailure,
        )
      }
    #if os(iOS)
      .fullScreenCover(item: self.$store.screenPresentation) { store in
        CrossPromoFeatureView(
          store: store,
          onImageLoadFailure: self.onImageLoadFailure,
        )
      }
    #endif
  }
}

public extension View {
  func crossPromoPresentations(
    store: Binding<StoreOf<CrossPromoFeature>?>,
    onImageLoadFailure: @escaping CrossPromoImageLoadFailureHandler = { _, _, _ in },
  ) -> some View {
    self.modifier(CrossPromoPresentationModifier(
      store: store,
      onImageLoadFailure: onImageLoadFailure,
    ))
  }
}

@MainActor
private extension StoreOf<CrossPromoFeature>? {
  var screenPresentation: Self {
    get { self?.campaign.style == .screen ? self : nil }
    set { self = newValue }
  }

  var sheetPresentation: Self {
    get { self?.campaign.style == .sheet ? self : nil }
    set { self = newValue }
  }
}

#if DEBUG
  #Preview("Regular") {
    CrossPromoFeatureView(
      store: .init(initialState: .init(campaign: .preview)) {
        EmptyReducer()
      },
    )
  }

  #Preview("Primary action only") {
    CrossPromoFeatureView(
      store: .init(initialState: .init(campaign: .primaryActionPreview)) {
        EmptyReducer()
      },
    )
  }

  #Preview("Compact height", traits: .fixedLayout(width: 375, height: 667)) {
    CrossPromoFeatureView(
      store: .init(initialState: .init(campaign: .preview)) {
        EmptyReducer()
      },
    )
  }

  #Preview("Accessibility text") {
    CrossPromoFeatureView(
      store: .init(initialState: .init(campaign: .preview)) {
        EmptyReducer()
      },
    )
    .environment(\.dynamicTypeSize, .accessibility3)
  }

  #Preview("Dark") {
    CrossPromoFeatureView(
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
#endif
