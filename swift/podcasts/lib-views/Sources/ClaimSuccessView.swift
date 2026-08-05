import GertieUI
import SwiftUI

public struct ClaimSuccessView: View {
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
    GertieResultScreen(
      icon: "checkmark.circle.fill",
      title: self.isTerminal
        ? lstr(.claimSuccessTerminalTitle)
        : lstr(.claimSuccessNeutralTitle),
      message: self.message,
      action: .button(
        self.buttonLabel ?? (self.isTerminal ? lstr(.claimDone) : lstr(.claimNext)),
      ) {
        self.onEvent(.continueTapped)
      },
    )
  }

  private var message: String? {
    if let entitlement = self.entitlement {
      self.subtitle(for: entitlement)
    } else {
      self.deviceName
    }
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
