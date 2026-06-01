import SwiftUI

public struct ClaimSuccessView: View {
  @Environment(\.colorScheme) var cs

  public enum Event: Equatable, Sendable {
    case continueTapped
  }

  let isTerminal: Bool
  let deviceName: String?
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    isTerminal: Bool,
    deviceName: String? = nil,
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.isTerminal = isTerminal
    self.deviceName = deviceName
    self.onEvent = onEvent
  }

  public var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))

      VStack(spacing: 8) {
        Text(self.isTerminal ? "You're all set" : "Account connected")
          .font(.system(size: 24, weight: .bold))
          .multilineTextAlignment(.center)

        if self.isTerminal {
          Text("Subscription active")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color(
              self.cs,
              light: .black.opacity(0.8),
              dark: .white.opacity(0.8),
            ))
        } else if let deviceName = self.deviceName {
          Text(deviceName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
        }
      }
      .multilineTextAlignment(.center)

      Spacer()

      BigButton(
        self.isTerminal ? "Done" : "Next",
        type: .button { self.onEvent(.continueTapped) },
        variant: .primary,
      )
    }
    .frame(maxWidth: 500)
    .padding(30)
    .screenGradientBackground()
  }
}

#Preview("Terminal") {
  ClaimSuccessView(isTerminal: true)
}

#Preview("Terminal (Dark)") {
  ClaimSuccessView(isTerminal: true)
    .preferredColorScheme(.dark)
}

#Preview("Neutral") {
  ClaimSuccessView(isTerminal: false, deviceName: "Bobby's iPhone")
}

#Preview("Neutral (Dark)") {
  ClaimSuccessView(isTerminal: false, deviceName: "Bobby's iPhone")
    .preferredColorScheme(.dark)
}
