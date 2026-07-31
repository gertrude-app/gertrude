import SwiftUI

public struct GertiePrimaryButtonStyle: PrimitiveButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    GertieButtonInteraction(isEnabled: self.isEnabled) { pressState in
      Button(configuration)
        .buttonStyle(GertiePrimaryButtonAppearance(pressState: pressState))
    }
  }
}

public struct GertieSecondaryButtonStyle: PrimitiveButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    GertieButtonInteraction(isEnabled: self.isEnabled) { pressState in
      Button(configuration)
        .buttonStyle(GertieSecondaryButtonAppearance(pressState: pressState))
    }
  }
}

private enum GertieButtonPressState: Equatable {
  case standard
  case pressing
  case cancelled

  func resolve(configurationIsPressed: Bool) -> Bool {
    switch self {
    case .standard:
      configurationIsPressed
    case .pressing:
      true
    case .cancelled:
      false
    }
  }
}

private struct GertieButtonInteraction<Content: View>: View {
  @GestureState private var pressState = GertieButtonPressState.standard

  private let isEnabled: Bool
  private let content: (GertieButtonPressState) -> Content

  init(
    isEnabled: Bool,
    @ViewBuilder content: @escaping (GertieButtonPressState) -> Content,
  ) {
    self.isEnabled = isEnabled
    self.content = content
  }

  @ViewBuilder var body: some View {
    #if os(iOS)
      if #available(iOS 18.0, *), self.isEnabled {
        ZStack {
          self.content(self.pressState)
        }
        .simultaneousGesture(self.pressGesture)
      } else {
        self.content(.standard)
      }
    #else
      self.content(.standard)
    #endif
  }

  private var pressGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .updating(self.$pressState) { value, state, _ in
        guard state != .cancelled else { return }
        state = max(abs(value.translation.width), abs(value.translation.height)) <= 10
          ? .pressing
          : .cancelled
      }
  }
}

private struct GertiePrimaryButtonAppearance: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.colorScheme) private var cs

  let pressState: GertieButtonPressState

  func makeBody(configuration: Configuration) -> some View {
    let isPressed = self.pressState.resolve(
      configurationIsPressed: configuration.isPressed,
    )

    VStack {
      configuration.label
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
          Gradient(colors: [Color.violet500, Color.violet600])
            .opacity(
              self.isEnabled
                ? (isPressed ? 0.8 : 1) : 0,
            ),
        )
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
    .padding(.vertical, 2)
    .padding(.horizontal, 1)
    .background(
      Gradient(colors: [
        Color.violet400,
        self.isEnabled ? Color.violet800 : Color.violet500,
      ]),
    )
    .clipShape(.rect(cornerRadius: 18, style: .continuous))
    .opacity(
      self.isEnabled
        ? (isPressed ? 0.8 : 1)
        : (self.cs == .light ? 0.6 : 0.4),
    )
    .scaleEffect(isPressed ? 0.98 : 1)
    .sensoryFeedback(
      .impact(weight: .medium, intensity: 0.7),
      trigger: isPressed,
    ) { wasPressed, isPressed in
      self.isEnabled && !wasPressed && isPressed
    }
  }
}

private struct GertieSecondaryButtonAppearance: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.colorScheme) private var cs

  let pressState: GertieButtonPressState

  func makeBody(configuration: Configuration) -> some View {
    let isPressed = self.pressState.resolve(
      configurationIsPressed: configuration.isPressed,
    )

    VStack {
      configuration.label
        .font(.headline)
        .foregroundStyle(
          Color(self.cs, light: Color.violet700, dark: Color.violet100),
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
          Gradient(colors: [
            Color(
              self.cs,
              light: Color.violet100.opacity(0.5),
              dark: .black.opacity(0.3),
            ),
            Color(
              self.cs,
              light: Color.violet200,
              dark: .white.opacity(0.03),
            ),
          ])
          .opacity(
            self.isEnabled
              ? (isPressed ? 0.8 : 1) : 0,
          ),
        )
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
    .padding(.vertical, 2)
    .padding(.horizontal, 1)
    .background(
      Gradient(colors: [
        Color(
          self.cs,
          light: Color.violet100.opacity(self.isEnabled ? 0.3 : 0.8),
          dark: .white.opacity(0.15),
        ),
        self.isEnabled
          ? Color(
            self.cs,
            light: Color.violet300.opacity(0.8),
            dark: .white.opacity(0.05),
          )
          : Color(
            self.cs,
            light: Color.violet100.opacity(0.8),
            dark: .white.opacity(0.1),
          ),
      ]),
    )
    .clipShape(.rect(cornerRadius: 18, style: .continuous))
    .opacity(
      self.isEnabled ? (isPressed ? 0.8 : 1) : 0.4,
    )
    .scaleEffect(isPressed ? 0.98 : 1)
    .sensoryFeedback(
      .impact(weight: .medium, intensity: 0.7),
      trigger: isPressed,
    ) { wasPressed, isPressed in
      self.isEnabled && !wasPressed && isPressed
    }
  }
}

public extension PrimitiveButtonStyle where Self == GertiePrimaryButtonStyle {
  static var gertiePrimary: GertiePrimaryButtonStyle {
    GertiePrimaryButtonStyle()
  }
}

public extension PrimitiveButtonStyle where Self == GertieSecondaryButtonStyle {
  static var gertieSecondary: GertieSecondaryButtonStyle {
    GertieSecondaryButtonStyle()
  }
}

#Preview("Primary button") {
  VStack(spacing: 16) {
    Button("Continue") {}
      .buttonStyle(.gertiePrimary)

    Button("Disabled") {}
      .buttonStyle(.gertiePrimary)
      .disabled(true)

    Button("Continue") {}
      .buttonStyle(.gertieSecondary)

    Button("Disabled") {}
      .buttonStyle(.gertieSecondary)
      .disabled(true)
  }
  .frame(width: 320)
  .padding()
}
