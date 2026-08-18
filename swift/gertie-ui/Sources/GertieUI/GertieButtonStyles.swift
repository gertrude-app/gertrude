import SwiftUI

public struct GertiePrimaryButtonStyle: PrimitiveButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  public func makeBody(configuration: Configuration) -> some View {
    GertieButtonInteraction(isEnabled: self.isEnabled) { pressState in
      Button(configuration)
        .buttonStyle(GertiePrimaryButtonAppearance(pressState: pressState))
    }
  }
}

public struct GertieSecondaryButtonStyle: PrimitiveButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

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

    configuration.label
      .font(.headline)
      .multilineTextAlignment(.center)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
      .background(
        Color(
          self.cs,
          light: .violet500,
          dark: .violet600.opacity(0.9),
        ),
      )
      .clipShape(.rect(cornerRadius: 16, style: .continuous))
      .opacity(self.isEnabled ? 1 : 0.5)
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

    configuration.label
      .font(.headline)
      .multilineTextAlignment(.center)
      .foregroundStyle(
        Color(self.cs, light: .violet500, dark: .violet400),
      )
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
      .background(
        Color(
          self.cs,
          light: .violet500.opacity(0.1),
          dark: .violet500.opacity(0.15),
        ),
      )
      .clipShape(.rect(cornerRadius: 16, style: .continuous))
      .opacity(self.isEnabled ? 1 : 0.5)
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

#Preview("Accessibility text") {
  VStack(spacing: 16) {
    Button("Get Gertrude Podcasts") {}
      .buttonStyle(.gertiePrimary)

    Button("Send a link to a parent") {}
      .buttonStyle(.gertieSecondary)
  }
  .frame(width: 320)
  .padding()
  .environment(\.dynamicTypeSize, .accessibility3)
}
