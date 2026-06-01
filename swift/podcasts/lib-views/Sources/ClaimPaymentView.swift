import SwiftUI

public struct ClaimPaymentView: View {
  @Environment(\.colorScheme) var cs

  public enum Event: Equatable, Sendable {
    case dismissTapped
  }

  public enum Need: Equatable, Sendable {
    case subscribe
    case renew
    case updatePayment
  }

  let shareUrl: String
  let need: Need
  let dismissLabel: String
  let statusDelay: Duration
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    shareUrl: String,
    need: Need,
    dismissLabel: String,
    statusDelay: Duration = .seconds(45),
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.shareUrl = shareUrl
    self.need = need
    self.dismissLabel = dismissLabel
    self.statusDelay = statusDelay
    self.onEvent = onEvent
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: "creditcard.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .frame(maxWidth: .infinity, alignment: .center)

      Spacer()
      Spacer()

      WaitingStatus(label: "Waiting for your subscription…", delay: self.statusDelay)

      Spacer()

      Text(self.bodyText)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))

      Text(self.shareUrl)
        .font(.system(size: 20, weight: .semibold, design: .monospaced))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)

      BigButton(
        self.dismissLabel,
        type: .button { self.onEvent(.dismissTapped) },
        variant: .secondary,
      )

      BigButton(
        "Send link",
        type: .share(self.shareUrl),
        variant: .primary,
        icon: "square.and.arrow.up",
      )
    }
    .frame(maxWidth: 500)
    .padding(30)
    .padding(.top, 50)
    .screenGradientBackground()
  }

  private var bodyText: String {
    switch self.need {
    case .subscribe:
      "Gertrude AM needs a Gertrude plan: light ($10/yr) or higher. Your account is connected but doesn't have one yet. Open this link on a parent's own device to subscribe:"
    case .renew:
      "Gertrude AM needs an active Gertrude plan: light ($10/yr) or higher. Open this link on a parent's own device to renew:"
    case .updatePayment:
      "Gertrude AM needs a payment update to keep your plan active. Open this link on a parent's own device to update payment:"
    }
  }
}

#Preview("Subscribe") {
  ClaimPaymentView(
    shareUrl: "https://gertrude.app/r/9f21ab",
    need: .subscribe,
    dismissLabel: "Not now",
    statusDelay: .seconds(2),
  )
}

#Preview("Renew") {
  ClaimPaymentView(
    shareUrl: "https://gertrude.app/r/9f21ab",
    need: .renew,
    dismissLabel: "Not now",
    statusDelay: .seconds(2),
  )
}

#Preview("Update payment") {
  ClaimPaymentView(
    shareUrl: "https://gertrude.app/r/9f21ab",
    need: .updatePayment,
    dismissLabel: "Not now",
    statusDelay: .seconds(2),
  )
}

#Preview("Subscribe (Dark)") {
  ClaimPaymentView(
    shareUrl: "https://parents.gertrude.app/settings",
    need: .subscribe,
    dismissLabel: "Not now",
    statusDelay: .seconds(2),
  )
  .preferredColorScheme(.dark)
}
