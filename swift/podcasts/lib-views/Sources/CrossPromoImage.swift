import GertieUI
import SwiftUI

public struct CrossPromoImage: View {
  private let url: String
  private let label: String?
  private let onLoadFailure: (@MainActor @Sendable (any Error) -> Void)?

  public init(
    url: String,
    label: String? = nil,
    onLoadFailure: (@MainActor @Sendable (any Error) -> Void)? = nil,
  ) {
    self.url = url
    self.label = label
    self.onLoadFailure = onLoadFailure
  }

  public var body: some View {
    if let url = URL(string: self.url) {
      RetryingAsyncImage(url: url, onFailure: self.onLoadFailure) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxHeight: 270)
          .accessibilityLabel(self.label ?? "")
      } placeholder: {
        ProgressView()
      }
      .frame(maxWidth: .infinity)
    }
  }
}

private struct CrossPromoSheetPreviewHost<Content: View>: View {
  let dismissable: Bool
  let content: (_ dismiss: @escaping () -> Void) -> Content
  @State private var presented: Bool = true

  init(
    dismissable: Bool = true,
    @ViewBuilder content: @escaping (_ dismiss: @escaping () -> Void) -> Content,
  ) {
    self.dismissable = dismissable
    self.content = content
  }

  var body: some View {
    ZStack {
      Color.gray.opacity(0.15).ignoresSafeArea()
      Button("Show promo") { self.presented = true }
        .buttonStyle(.borderedProminent)
    }
    .sheet(isPresented: self.$presented) {
      self.content { self.presented = false }
        .interactiveDismissDisabled(!self.dismissable)
    }
  }
}

#Preview("Cross-promo · primary only") {
  CrossPromoSheetPreviewHost { dismiss in
    GertieActionScreen(
      message:
      "Did you know about Gertrude Blocker?\n\nThe iOS parental controls app from the makers of Gertrude Podcasts — block apps, websites, and more.",
      icon: .announcement,
      action: .button("Check it out") { dismiss() },
    )
  }
}

#Preview("Cross-promo · primary + secondary") {
  CrossPromoSheetPreviewHost { dismiss in
    GertieActionScreen(
      message:
      "Looking for kid-safe music?\n\nGertrude Music is a parent-curated music app for kids — no ads, no autoplay rabbit holes.",
      icon: .announcement,
      actions: [
        .button("Get Gertrude Music") { dismiss() },
        .button("No thanks") { dismiss() },
      ],
    )
  }
}

#Preview("Cross-promo · non-dismissable") {
  CrossPromoSheetPreviewHost(dismissable: false) { dismiss in
    GertieActionScreen(
      message: "Important announcement\n\nThis sheet can't be swiped down — only the button dismisses it.",
      icon: .announcement,
      action: .button("Got it") { dismiss() },
    )
  }
}

#Preview("Cross-promo · with image") {
  CrossPromoSheetPreviewHost { dismiss in
    GertieActionScreen(
      message:
      "Meet Gertrude Music\n\nKid-safe, parent-curated music — no ads, no autoplay rabbit holes.",
      icon: .announcement,
      actions: [
        .button("Get Gertrude Music") { dismiss() },
        .button("No thanks") { dismiss() },
      ],
      supplementPlacement: .beforeMessage,
    ) {
      CrossPromoImage(
        url: "https://raw.githubusercontent.com/gertrude-app/gertrude/master/web/dash/app/public/og-image.jpg",
        label: "Gertrude",
      )
    }
  }
}

#Preview("Cross-promo · square image") {
  CrossPromoSheetPreviewHost { dismiss in
    GertieActionScreen(
      message: "Try Gertrude Podcasts\n\nKid-safe podcasts for the whole family.",
      icon: .announcement,
      actions: [
        .button("Get the app") { dismiss() },
        .button("Maybe later") { dismiss() },
      ],
      supplementPlacement: .beforeMessage,
    ) {
      CrossPromoImage(
        url: "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/xpromo/gertrude-am-icon-512.png",
        label: "Gertrude Podcasts app icon",
      )
    }
  }
}
