import SwiftUI

struct ButtonScreenView: View {
  @Environment(\.colorScheme) var cs
  @ScaledMetric(relativeTo: .title) private var titleScale = 1.0
  @ScaledMetric(relativeTo: .body) private var bodyScale = 1.0

  struct Config {
    var text: String
    var type: BigButton.ButtonType
    var animate: Bool
    var asyncAction: Bool
    var disabled: Bool

    init(
      text: String,
      type: BigButton.ButtonType,
      animate: Bool = true,
      asyncAction: Bool = false,
      disabled: Bool = false,
    ) {
      self.text = text
      self.type = type
      self.animate = animate
      self.asyncAction = asyncAction
      self.disabled = disabled
    }

    init(
      _ text: String,
      animate: Bool = true,
      asyncAction: Bool = false,
      disabled: Bool = false,
      _ action: @escaping () -> Void,
    ) {
      self.init(
        text: text,
        type: .button(action),
        animate: animate,
        asyncAction: asyncAction,
        disabled: disabled,
      )
    }
  }

  let text: String
  let primaryButtonConfig: Config?
  let secondaryButtonConfig: Config?
  let tertiaryButtonConfig: Config?
  let primaryLooksLikeSecondary: Bool
  let listItems: [String]?
  let image: String?
  let screenType: ScreenType
  let screenIdentifier: String?

  @State private var showBg = true
  @State private var iconOffset = Vector(x: 0, y: -20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var primaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var secondaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var tertiaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var btnTapped = false

  var icon: String {
    switch self.screenType {
    case .info: "info.circle"
    case .question: "questionmark.circle"
    case .error: "exclamationmark.circle"
    }
  }

  init(
    text: String,
    primary: Config? = nil,
    secondary: Config? = nil,
    tertiary: Config? = nil,
    listItems: [String]? = nil,
    image: String? = nil,
    screenType: ScreenType = .info,
    primaryLooksLikeSecondary: Bool = false,
    screenIdentifier: String? = nil,
  ) {
    self.text = text
    self.screenType = screenType
    self.screenIdentifier = screenIdentifier
    self.listItems = listItems
    self.image = image
    self.primaryButtonConfig = primary
    self.secondaryButtonConfig = secondary
    self.tertiaryButtonConfig = tertiary
    self.primaryLooksLikeSecondary = primaryLooksLikeSecondary
  }

  private struct Metrics {
    var isCompact: Bool
    var spacing: CGFloat
    var iconSize: CGFloat
    var listPadBottom: CGFloat
    var buttonPadTop: CGFloat
    var insets: EdgeInsets

    static let regular = Metrics(
      isCompact: false,
      spacing: 16,
      iconSize: 40,
      listPadBottom: 20,
      buttonPadTop: 12,
      insets: EdgeInsets(top: 80, leading: 30, bottom: 30, trailing: 30),
    )

    static let compact = Metrics(
      isCompact: true,
      spacing: 12,
      iconSize: 34,
      listPadBottom: 8,
      buttonPadTop: 8,
      insets: EdgeInsets(top: 42, leading: 22, bottom: 22, trailing: 22),
    )
  }

  var body: some View {
    AdaptiveScreen(backgroundVisible: self.showBg) { isCompact in
      self.content(m: isCompact ? .compact : .regular)
    }
  }

  private func content(m: Metrics) -> some View {
    VStack(alignment: .leading, spacing: m.spacing) {
      Image(systemName: self.icon)
        .font(.system(size: m.iconSize * self.titleScale, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .swooshIn(tracking: self.$iconOffset, to: .zero, after: .zero, for: .milliseconds(800))
        .frame(maxWidth: .infinity, alignment: .center)

      Spacer(minLength: m.isCompact ? 10 : nil)

      if let image = self.image {
        self.screenImage(image, isCompact: m.isCompact)
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))
      }

      Text(self.text)
        .font(.system(size: 18 * self.bodyScale, weight: .medium))
        .fixedSize(horizontal: false, vertical: true)
        .optionalAccessibilityIdentifier(self.screenIdentifier)
        .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))

      if let listItems = self.listItems {
        VStack(alignment: .leading) {
          ForEach(listItems, id: \.self) { item in
            HStack(alignment: .top, spacing: 12) {
              Image(systemName: "circle.fill")
                .font(.system(size: 6 * self.bodyScale))
                .padding(.top, 7)
                .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
              Text(item)
                .font(.system(size: 16 * self.bodyScale, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(0.8)
              Spacer()
            }
            .padding(.leading, 14)
          }
        }
        .padding(.bottom, m.listPadBottom)
        .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))
      }

      if let config = self.primaryButtonConfig {
        if self.primaryButtonStatus.isLoading {
          self.LoadingButton
        } else {
          BigButton(
            config.text,
            type: self.withOrWithoutVanishingAnimations(
              type: config.type,
              animate: config.animate,
              asyncAction: config.asyncAction,
              isLoading: self.$primaryButtonStatus.isLoading,
            ),
            variant: self.primaryLooksLikeSecondary ? .secondary : .primary,
            disabled: config.disabled,
            accessibilityIdentifier: "btn-primary",
          )
          .swooshIn(
            tracking: self.$primaryButtonStatus.offset,
            to: .zero,
            after: .milliseconds(150),
            for: .milliseconds(800),
          )
          .padding(.top, m.buttonPadTop)
        }
      }

      if let config = self.secondaryButtonConfig {
        if self.secondaryButtonStatus.isLoading {
          self.LoadingButton
        } else {
          BigButton(
            config.text,
            type: self.withOrWithoutVanishingAnimations(
              type: config.type,
              animate: config.animate,
              asyncAction: config.asyncAction,
              isLoading: self.$secondaryButtonStatus.isLoading,
            ),
            variant: .secondary,
            disabled: config.disabled,
            accessibilityIdentifier: "btn-secondary",
          )
          .swooshIn(
            tracking: self.$secondaryButtonStatus.offset,
            to: .zero,
            after: .milliseconds(300),
            for: .milliseconds(800),
          )
        }
      }

      if let config = self.tertiaryButtonConfig {
        if self.tertiaryButtonStatus.isLoading {
          self.LoadingButton
        } else {
          BigButton(
            config.text,
            type: self.withOrWithoutVanishingAnimations(
              type: config.type,
              animate: config.animate,
              asyncAction: config.asyncAction,
              isLoading: self.$tertiaryButtonStatus.isLoading,
            ),
            variant: .secondary,
            disabled: config.disabled,
            accessibilityIdentifier: "onboarding-tertiary-button",
          )
          .swooshIn(
            tracking: self.$tertiaryButtonStatus.offset,
            to: .zero,
            after: .milliseconds(450),
            for: .milliseconds(800),
          )
        }
      }
    }
    .frame(maxWidth: 500)
    .padding(m.insets)
  }

  @ViewBuilder
  private func screenImage(_ image: String, isCompact: Bool) -> some View {
    if isCompact {
      Image(image)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: image.contains("IOS26") ? 260 : 300)
        .padding(.bottom, 8)
    } else {
      Image(image)
        .scaleEffect(image.contains("IOS26") ? 1.25 : 1.0)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 50)
    }
  }

  var LoadingButton: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .padding(.vertical, 21)
  }

  func withOrWithoutVanishingAnimations(
    type: BigButton.ButtonType,
    animate: Bool,
    asyncAction: Bool,
    isLoading: Binding<Bool>,
  )
    -> BigButton.ButtonType {
    switch type {
    case .link(let url):
      .link(url)
    case .share(let string):
      .share(string)
    case .button(let onTap):
      .button {
        guard !self.btnTapped else { return }
        self.btnTapped = true
        if animate {
          self.vanishingAnimations()
          delayed(by: .milliseconds(800)) {
            onTap()
          }
        } else if asyncAction {
          isLoading.wrappedValue = true
          onTap()
        } else {
          onTap()
        }
      }
    }
  }

  func vanishingAnimations() {
    withAnimation {
      self.iconOffset.y = -20
      self.tertiaryButtonStatus.offset.y = 20
    }

    delayed(by: .milliseconds(100)) {
      withAnimation {
        self.secondaryButtonStatus.offset.y = 20
        self.showBg = false
      }
    }

    delayed(by: .milliseconds(200)) {
      withAnimation {
        self.primaryButtonStatus.offset.y = 20
      }
    }

    delayed(by: .milliseconds(300)) {
      withAnimation {
        self.textOffset.y = 20
      }
    }
  }

  enum ScreenType {
    case info
    case question
    case error
  }
}

#Preview("No button") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    screenType: .error,
  )
}

#Preview("1 button") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Next", type: .button {}, animate: true),
  )
}

#Preview("1 button with async action") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(
      text: "Next", type: .button {}, animate: false, asyncAction: true,
    ),
  )
}

#Preview("2 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
  )
}

#Preview("2 buttons (both secondary)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    primaryLooksLikeSecondary: true,
  )
}

#Preview("3 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    tertiary: ButtonScreenView.Config(text: "Do another thing", type: .button {}, animate: true),
  )
}

#Preview("list items (1 button)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    listItems: ["Lorem ipsum dolor", "Sit amet consectetur adipiscing elit"],
  )
}

#Preview("list items (2 buttons)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    listItems: [
      "Lorem ipsum dolor",
      "Sit amet consectetur adipiscing elit",
      "Jimmy Carter died recently and there was a national day of morning",
    ],
  )
}

#Preview("list items (3 buttons)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    tertiary: ButtonScreenView.Config(text: "Do another thing", type: .button {}, animate: true),
    listItems: [
      "Lorem ipsum dolor",
      "Sit amet consectetur adipiscing elit",
      "Jimmy Carter died recently and there was a national day of morning",
    ],
  )
}

#Preview("with image") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    image: "AllowContentFilter",
  )
}

#Preview("Screen Time Access (< iOS 26)") {
  ButtonScreenView(
    text: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you're supposed to click “Don’t Allow”.",
    primary: .init("Got it, next") {},
    image: "AllowScreenTimeAccess",
  )
}

#Preview("Screen Time Access (iOS 26+)") {
  ButtonScreenView(
    text: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you're supposed to click “Don’t Allow”.",
    primary: .init("Got it, next") {},
    image: "AllowScreenTimeAccessIOS26",
  )
}

#Preview("Content Filter (< iOS 26)") {
  ButtonScreenView(
    text: "Again, don't get tricked! Be sure to click “Allow”, even though it looks like you're supposed to click “Don’t Allow”.",
    primary: .init("Got it, next") {},
    image: "AllowContentFilter",
  )
}

#Preview("Content Filter (iOS 26+)") {
  ButtonScreenView(
    text: "Again, don't get tricked! Be sure to click “Allow”, even though it looks like you're supposed to click “Don’t Allow”.",
    primary: .init("Got it, next") {},
    image: "AllowContentFilterIOS26",
  )
}
