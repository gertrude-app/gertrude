import SwiftUI

#if canImport(UIKit)
  import UIKit
#else
  import LibCore
#endif

public struct ButtonScreenView: View {
  @Environment(\.colorScheme) var cs

  public struct UrlInputConfig: Sendable {
    var placeholder: String
    var buttonText: String
    var onSubmit: @MainActor @Sendable (String) -> Void

    public init(
      placeholder: String = "Enter URL",
      buttonText: String = "Submit",
      onSubmit: @MainActor @escaping @Sendable (String) -> Void
    ) {
      self.placeholder = placeholder
      self.buttonText = buttonText
      self.onSubmit = onSubmit
    }
  }

  public struct Config: Sendable {
    var text: String
    var type: ButtonType
    var animate: Bool
    var asyncAction: Bool

    public init(
      text: String,
      type: ButtonType,
      animate: Bool = true,
      asyncAction: Bool = false
    ) {
      self.text = text
      self.type = type
      self.animate = animate
      self.asyncAction = asyncAction
    }

    public init(
      _ text: String,
      animate: Bool = true,
      asyncAction: Bool = false,
      _ action: @MainActor @escaping @Sendable () -> Void
    ) {
      self.init(
        text: text,
        type: .button(action),
        animate: animate,
        asyncAction: asyncAction
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
  let urlInputConfig: UrlInputConfig?

  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: -20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var primaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var secondaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var tertiaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var urlText = ""
  @State private var urlInputOffset = Vector(x: 0, y: 20)
  @FocusState private var isUrlFieldFocused: Bool

  var icon: String {
    switch self.screenType {
    case .info: "info.circle"
    case .question: "questionmark.circle"
    case .error: "exclamationmark.circle"
    }
  }

  public init(
    text: String,
    primary: Config? = nil,
    secondary: Config? = nil,
    tertiary: Config? = nil,
    listItems: [String]? = nil,
    image: String? = nil,
    screenType: ScreenType = .info,
    primaryLooksLikeSecondary: Bool = false,
    urlInput: UrlInputConfig? = nil
  ) {
    self.text = text
    self.screenType = screenType
    self.listItems = listItems
    self.image = image
    self.primaryButtonConfig = primary
    self.secondaryButtonConfig = secondary
    self.tertiaryButtonConfig = tertiary
    self.primaryLooksLikeSecondary = primaryLooksLikeSecondary
    self.urlInputConfig = urlInput
  }

  public var body: some View {
    ZStack {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
            .clear,
          ])
        )
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.backgroundFadeSmooth) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: self.icon)
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .zero, for: .milliseconds(800))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        if let image = self.image {
          Image(image)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
            .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))
        }

        Text(self.text)
          .font(.system(size: 18, weight: .medium))
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))

        if let listItems = self.listItems {
          VStack(alignment: .leading) {
            ForEach(listItems, id: \.self) { item in
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: "circle.fill")
                  .font(.system(size: 6))
                  .padding(.top, 7)
                  .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
                Text(item)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
                  .opacity(0.8)
                Spacer()
              }
              .padding(.leading, 14)
            }
          }
          .padding(.bottom, 20)
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))
        }

        if let urlConfig = self.urlInputConfig {
          VStack(spacing: 40) {
            TextField(urlConfig.placeholder, text: self.$urlText)
              .textInputAutocapitalization(.never)
              .font(.system(size: 22, weight: .medium))
              .textContentType(.URL)
              .disableAutocorrection(true)
              .focused(self.$isUrlFieldFocused)
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color(self.cs, light: .white, dark: .black))
              )
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(
                    Color(self.cs, light: .gray.opacity(0.3), dark: .gray.opacity(0.5)),
                    lineWidth: 1
                  )
              )
              .onAppear {
                self.isUrlFieldFocused = true
              }

            BigButton(
              urlConfig.buttonText,
              type: .button { urlConfig.onSubmit(self.urlText) },
              variant: .primary,
              disabled: self.urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
          }
          .swooshIn(
            tracking: self.$urlInputOffset,
            to: .zero,
            after: .milliseconds(100),
            for: .milliseconds(800)
          )
          .padding(.bottom, 20)
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
                isLoading: self.$primaryButtonStatus.isLoading
              ),
              variant: self.primaryLooksLikeSecondary ? .secondary : .primary
            )
            .swooshIn(
              tracking: self.$primaryButtonStatus.offset,
              to: .zero,
              after: .milliseconds(150),
              for: .milliseconds(800)
            )
            .padding(.top, 12)
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
                isLoading: self.$secondaryButtonStatus.isLoading
              ),
              variant: .secondary
            )
            .swooshIn(
              tracking: self.$secondaryButtonStatus.offset,
              to: .zero,
              after: .milliseconds(300),
              for: .milliseconds(800)
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
                isLoading: self.$tertiaryButtonStatus.isLoading
              ),
              variant: .secondary
            )
            .swooshIn(
              tracking: self.$tertiaryButtonStatus.offset,
              to: .zero,
              after: .milliseconds(450),
              for: .milliseconds(800)
            )
          }
        }
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
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
    type: ButtonType,
    animate: Bool,
    asyncAction: Bool,
    isLoading: Binding<Bool>
  ) -> ButtonType {
    switch type {
    case .link(let url):
      .link(url)
    case .share(let string):
      .share(string)
    case .button(let onTap):
      .button {
        if animate {
          Task { @MainActor in
            self.vanishingAnimations()
          }
          delayed(by: .milliseconds(800)) {
            Task { @MainActor in
              onTap()
            }
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

  @MainActor func vanishingAnimations() {
    withAnimation {
      self.iconOffset.y = -20
      self.tertiaryButtonStatus.offset.y = 20
    }

    delayed(by: .milliseconds(100)) {
      Task { @MainActor in
        withAnimation {
          self.secondaryButtonStatus.offset.y = 20
          self.showBg = false
        }
      }
    }

    delayed(by: .milliseconds(200)) {
      Task { @MainActor in
        withAnimation {
          self.primaryButtonStatus.offset.y = 20
          self.urlInputOffset.y = 20
        }
      }
    }

    delayed(by: .milliseconds(300)) {
      Task { @MainActor in
        withAnimation {
          self.textOffset.y = 20
        }
      }
    }
  }

  public enum ScreenType {
    case info
    case question
    case error
  }
}

#Preview("No button") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    screenType: .error
  )
}

#Preview("1 button") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Next", type: .button {}, animate: true)
  )
}

#Preview("1 button with async action") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(
      text: "Next", type: .button {}, animate: false, asyncAction: true
    )
  )
}

#Preview("2 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true)
  )
}

#Preview("2 buttons (both secondary)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    primaryLooksLikeSecondary: true
  )
}

#Preview("3 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    tertiary: ButtonScreenView.Config(text: "Do another thing", type: .button {}, animate: true)
  )
}

#Preview("list items (1 button)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    listItems: ["Lorem ipsum dolor", "Sit amet consectetur adipiscing elit"]
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
    ]
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
    ]
  )
}

#Preview("with image") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    image: "AllowContentFilter"
  )
}

#Preview("URL input") {
  ButtonScreenView(
    text: "Enter a podcast RSS feed URL to add to your library:",
    urlInput: ButtonScreenView.UrlInputConfig(
      placeholder: "https://example.com/feed.rss",
      buttonText: "Add Feed"
    ) { url in
      print("Submitted URL: \(url)")
    }
  )
}

#Preview("URL input with button") {
  ButtonScreenView(
    text: "Add a new podcast feed or browse our recommendations:",
    primary: ButtonScreenView.Config(
      text: "Browse Recommendations",
      type: .button {},
      animate: true
    ),
    urlInput: ButtonScreenView.UrlInputConfig(
      placeholder: "https://example.com/feed.rss",
      buttonText: "Add Feed"
    ) { url in
      print("Submitted URL: \(url)")
    }
  )
}
