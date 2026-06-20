import SwiftUI

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
    ButtonScreenView(
      text:
      "Did you know about Gertrude Blocker?\n\nThe iOS parental controls app from the makers of Gertrude AM — block apps, websites, and more.",
      primary: .init("Check it out", animate: false) { dismiss() },
      screenType: .announcement,
    )
  }
}

#Preview("Cross-promo · primary + secondary") {
  CrossPromoSheetPreviewHost { dismiss in
    ButtonScreenView(
      text:
      "Looking for kid-safe music?\n\nGertrude Music is a parent-curated music app for kids — no ads, no autoplay rabbit holes.",
      primary: .init("Get Gertrude Music", animate: false) { dismiss() },
      secondary: .init("No thanks", animate: false) { dismiss() },
      screenType: .announcement,
    )
  }
}

#Preview("Cross-promo · non-dismissable") {
  CrossPromoSheetPreviewHost(dismissable: false) { dismiss in
    ButtonScreenView(
      text:
      "Important announcement\n\nThis sheet can't be swiped down — only the button dismisses it.",
      primary: .init("Got it", animate: false) { dismiss() },
      screenType: .announcement,
    )
  }
}

#Preview("Cross-promo · with image") {
  CrossPromoSheetPreviewHost { dismiss in
    ButtonScreenView(
      text:
      "Meet Gertrude Music\n\nKid-safe, parent-curated music — no ads, no autoplay rabbit holes.",
      primary: .init("Get Gertrude Music", animate: false) { dismiss() },
      secondary: .init("No thanks", animate: false) { dismiss() },
      remoteImage: .init(
        url: "https://raw.githubusercontent.com/gertrude-app/gertrude/master/web/dash/app/public/og-image.jpg",
        label: "Gertrude",
      ),
      screenType: .announcement,
    )
  }
}

#Preview("Cross-promo · square image") {
  CrossPromoSheetPreviewHost { dismiss in
    ButtonScreenView(
      text:
      "Try Gertrude AM\n\nKid-safe podcasts for the whole family.",
      primary: .init("Get the app", animate: false) { dismiss() },
      secondary: .init("Maybe later", animate: false) { dismiss() },
      remoteImage: .init(
        url: "https://raw.githubusercontent.com/gertrude-app/gertrude/master/swift/podcasts/app/Assets.xcassets/AppIcon.appiconset/radio-1024.png",
        label: "Gertrude AM app icon",
      ),
      screenType: .announcement,
    )
  }
}
