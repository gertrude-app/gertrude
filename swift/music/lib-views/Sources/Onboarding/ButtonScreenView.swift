import SwiftUI

struct ButtonScreenView: View {
  @Environment(\.colorScheme) private var colorScheme

  struct Config: Sendable {
    var text: String
    var type: ButtonType
    var animate: Bool
    var asyncAction: Bool
    var disabled: Bool

    init(
      text: String,
      type: ButtonType,
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
      _ action: @MainActor @escaping @Sendable () -> Void,
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
  let screenType: ScreenType

  @State private var showBackground = false
  @State private var iconOffset = Vector(x: 0, y: -20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var primaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var secondaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var tertiaryButtonStatus = (offset: Vector(x: 0, y: 20), isLoading: false)
  @State private var buttonTapped = false

  var body: some View {
    ZStack {
      ScreenBackground(showBackground: self.showBackground)

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: self.icon)
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.colorScheme, light: .violet500, dark: .violet400))
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .zero, for: .milliseconds(800))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        Text(self.text)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
          .fixedSize(horizontal: false, vertical: true)
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))

        if let listItems = self.listItems {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(listItems, id: \.self) { item in
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: "circle.fill")
                  .font(.system(size: 6))
                  .padding(.top, 7)
                  .foregroundStyle(Color(self.colorScheme, light: .violet500, dark: .violet400))
                Text(item)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
                  .opacity(0.8)
                Spacer()
              }
              .padding(.leading, 14)
            }
          }
          .padding(.bottom, 20)
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))
        }

        if let config = self.primaryButtonConfig {
          self.button(
            config,
            status: self.$primaryButtonStatus,
            delay: .milliseconds(150),
            variant: self.primaryLooksLikeSecondary ? .secondary : .primary,
          )
          .padding(.top, 12)
        }

        if let config = self.secondaryButtonConfig {
          self.button(
            config,
            status: self.$secondaryButtonStatus,
            delay: .milliseconds(300),
            variant: .secondary,
          )
        }

        if let config = self.tertiaryButtonConfig {
          self.button(
            config,
            status: self.$tertiaryButtonStatus,
            delay: .milliseconds(450),
            variant: .secondary,
          )
        }
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
    .onAppear {
      withAnimation(.smooth(duration: 0.7)) {
        self.showBackground = true
      }
    }
  }

  init(
    text: String,
    primary: Config? = nil,
    secondary: Config? = nil,
    tertiary: Config? = nil,
    listItems: [String]? = nil,
    screenType: ScreenType = .info,
    primaryLooksLikeSecondary: Bool = false,
  ) {
    self.text = text
    self.primaryButtonConfig = primary
    self.secondaryButtonConfig = secondary
    self.tertiaryButtonConfig = tertiary
    self.primaryLooksLikeSecondary = primaryLooksLikeSecondary
    self.listItems = listItems
    self.screenType = screenType
  }

  private var icon: String {
    switch self.screenType {
    case .info: "info.circle"
    case .question: "questionmark.circle"
    case .error: "exclamationmark.circle"
    case .announcement: "sparkles"
    case .music: "music.note.list"
    case .link: "link.circle"
    }
  }

  @ViewBuilder
  private func button(
    _ config: Config,
    status: Binding<(offset: Vector, isLoading: Bool)>,
    delay: Duration,
    variant: BigButton.Variant,
  ) -> some View {
    if status.wrappedValue.isLoading {
      HStack {
        Spacer()
        ProgressView()
        Spacer()
      }
      .padding(.vertical, 21)
    } else {
      BigButton(
        config.text,
        type: self.withOrWithoutVanishingAnimations(
          type: config.type,
          animate: config.animate,
          asyncAction: config.asyncAction,
          isLoading: Binding(
            get: { status.wrappedValue.isLoading },
            set: { status.wrappedValue.isLoading = $0 },
          ),
        ),
        variant: variant,
        disabled: config.disabled,
      )
      .swooshIn(
        tracking: Binding(
          get: { status.wrappedValue.offset },
          set: { status.wrappedValue.offset = $0 },
        ),
        to: .zero,
        after: delay,
        for: .milliseconds(800),
      )
    }
  }

  private func withOrWithoutVanishingAnimations(
    type: ButtonType,
    animate: Bool,
    asyncAction: Bool,
    isLoading: Binding<Bool>,
  ) -> ButtonType {
    switch type {
    case .link(let url):
      .link(url)
    case .share(let string):
      .share(string)
    case .button(let onTap):
      .button {
        if animate {
          guard !self.buttonTapped else { return }
          self.buttonTapped = true
          self.vanishingAnimations()
          delayed(by: .milliseconds(800)) {
            onTap()
          }
        } else if asyncAction {
          guard !self.buttonTapped else { return }
          self.buttonTapped = true
          isLoading.wrappedValue = true
          onTap()
        } else {
          onTap()
        }
      }
    }
  }

  private func vanishingAnimations() {
    withAnimation {
      self.iconOffset.y = -20
      self.tertiaryButtonStatus.offset.y = 20
    }

    delayed(by: .milliseconds(100)) {
      withAnimation {
        self.secondaryButtonStatus.offset.y = 20
        self.showBackground = false
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
    case announcement
    case music
    case link
  }
}

#Preview("Music permission") {
  ButtonScreenView(
    text: "Gertrude Music needs permission to use Apple Music so approved albums can play.",
    primary: .init("Continue") {},
    screenType: .music,
  )
}
