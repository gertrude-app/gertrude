import GertieUI
import SwiftUI

public struct ClaimSuccessView: View {
  @Environment(\.colorScheme) var cs

  public enum Event: Equatable, Sendable {
    case continueTapped
  }

  public enum Entitlement: Equatable, Sendable {
    case paid
    case trial
    case complimentary
    case legacy
  }

  let entitlement: Entitlement?
  let deviceName: String?
  let buttonLabel: String?
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    entitlement: Entitlement?,
    deviceName: String? = nil,
    buttonLabel: String? = nil,
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.entitlement = entitlement
    self.deviceName = deviceName
    self.buttonLabel = buttonLabel
    self.onEvent = onEvent
  }

  // an entitled (terminal) claim needs no follow-on payment step
  private var isTerminal: Bool {
    self.entitlement != nil
  }

  public var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .accessibilityHidden(true)

      VStack(spacing: 8) {
        Text(self.isTerminal ? lstr(.claimSuccessTerminalTitle) : lstr(.claimSuccessNeutralTitle))
          .font(.system(size: 24, weight: .bold))
          .multilineTextAlignment(.center)

        if let entitlement = self.entitlement {
          Text(self.subtitle(for: entitlement))
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

      Button(self.buttonLabel ?? (self.isTerminal ? lstr(.claimDone) : lstr(.claimNext))) {
        self.onEvent(.continueTapped)
      }
      .buttonStyle(.gertiePrimary)
    }
    .frame(maxWidth: 500)
    .padding(30)
    .gertieScreenBackground()
  }

  private func subtitle(for entitlement: Entitlement) -> String {
    switch entitlement {
    case .paid: lstr(.claimSuccessTerminalSubtitle)
    case .trial: lstr(.claimSuccessTerminalSubtitleTrial)
    case .complimentary: lstr(.claimSuccessTerminalSubtitleComplimentary)
    case .legacy: lstr(.claimSuccessTerminalSubtitleLegacy)
    }
  }
}

#Preview("Paid") {
  ClaimSuccessView(entitlement: .paid)
}

#Preview("Paid (Dark)") {
  ClaimSuccessView(entitlement: .paid)
    .preferredColorScheme(.dark)
}

#Preview("Trial") {
  ClaimSuccessView(entitlement: .trial)
}

#Preview("Complimentary") {
  ClaimSuccessView(entitlement: .complimentary)
}

#Preview("Legacy") {
  ClaimSuccessView(entitlement: .legacy)
}

#Preview("Neutral") {
  ClaimSuccessView(entitlement: nil, deviceName: "Bobby’s iPhone")
}

#Preview("Neutral (Dark)") {
  ClaimSuccessView(entitlement: nil, deviceName: "Bobby’s iPhone")
    .preferredColorScheme(.dark)
}
