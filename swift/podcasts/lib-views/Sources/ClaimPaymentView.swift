import GertieUI
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
  let deviceType: String
  let statusDelay: Duration
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    shareUrl: String,
    need: Need,
    dismissLabel: String,
    deviceType: String,
    statusDelay: Duration = .seconds(45),
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.shareUrl = shareUrl
    self.need = need
    self.dismissLabel = dismissLabel
    self.deviceType = deviceType
    self.statusDelay = statusDelay
    self.onEvent = onEvent
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      GertieScreenIconBadge(systemName: "creditcard.circle")

      Spacer()
      Spacer()

      GertieWaitingStatus(label: lstr(.claimPaymentWatching), delay: self.statusDelay)

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

      Button(self.dismissLabel) {
        self.onEvent(.dismissTapped)
      }
      .buttonStyle(.gertieSecondary)

      ShareLink(item: self.shareUrl) {
        HStack(spacing: 8) {
          Text(lstr(.claimSendLink))
          Image(systemName: "square.and.arrow.up")
        }
      }
      .buttonStyle(.gertiePrimary)
    }
    .frame(maxWidth: 500)
    .padding(30)
    .padding(.top, 50)
    .gertieScreenBackground()
  }

  private var bodyText: String {
    switch self.need {
    case .subscribe:
      String(format: lstr(.claimPaymentSubscribe), self.deviceType)
    case .renew:
      String(format: lstr(.claimPaymentRenew), self.deviceType)
    case .updatePayment:
      String(format: lstr(.claimPaymentUpdatePayment), self.deviceType)
    }
  }
}

#Preview("Subscribe") {
  ClaimPaymentView(
    shareUrl: "https://gertrude.app/r/9f21ab",
    need: .subscribe,
    dismissLabel: "Not now",
    deviceType: "iPhone",
    statusDelay: .seconds(2),
  )
}

#Preview("Renew") {
  ClaimPaymentView(
    shareUrl: "https://gertrude.app/r/9f21ab",
    need: .renew,
    dismissLabel: "Not now",
    deviceType: "iPhone",
    statusDelay: .seconds(2),
  )
}

#Preview("Update payment") {
  ClaimPaymentView(
    shareUrl: "https://gertrude.app/r/9f21ab",
    need: .updatePayment,
    dismissLabel: "Not now",
    deviceType: "iPhone",
    statusDelay: .seconds(2),
  )
}

#Preview("Subscribe (Dark)") {
  ClaimPaymentView(
    shareUrl: "https://parents.gertrude.app/settings",
    need: .subscribe,
    dismissLabel: "Not now",
    deviceType: "iPad",
    statusDelay: .seconds(2),
  )
  .preferredColorScheme(.dark)
}
