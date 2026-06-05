import SwiftUI

public struct ClaimCodeView: View {
  @Environment(\.colorScheme) var cs

  public enum Event: Equatable, Sendable {
    case retryTapped
    case dismissTapped
  }

  let code: Int?
  let failed: Bool
  let dismissLabel: String
  let deviceType: String
  let statusDelay: Duration
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    code: Int?,
    failed: Bool = false,
    dismissLabel: String,
    deviceType: String,
    statusDelay: Duration = .seconds(45),
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.code = code
    self.failed = failed
    self.dismissLabel = dismissLabel
    self.deviceType = deviceType
    self.statusDelay = statusDelay
    self.onEvent = onEvent
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: "link.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .frame(maxWidth: .infinity, alignment: .center)

      Spacer()

      if self.failed {
        self.errorContent
        Spacer()
      } else if let code = self.code {
        Spacer()
        Spacer()

        WaitingStatus(label: lstr(.claimCodeWatching), delay: self.statusDelay)

        Spacer()

        self.codeContent(code)
      } else {
        self.loadingContent
        Spacer()
      }

      if self.failed || self.code != nil {
        BigButton(
          self.dismissLabel,
          type: .button { self.onEvent(.dismissTapped) },
          variant: .secondary,
        )
      }

      if !self.failed, let code = self.code {
        BigButton(
          lstr(.claimSendLink),
          type: .share(self.claimUrl(code)),
          variant: .primary,
          icon: "square.and.arrow.up",
        )
      }

      if self.failed {
        BigButton(
          lstr(.claimTryAgain),
          type: .button { self.onEvent(.retryTapped) },
          variant: .primary,
        )
      }
    }
    .frame(maxWidth: 500)
    .padding(30)
    .padding(.top, 50)
    .screenGradientBackground()
  }

  @ViewBuilder private func codeContent(_ code: Int) -> some View {
    Text(
      String(format: lstr(.claimCodeInstructions), self.deviceType),
    )
    .font(.system(size: 17, weight: .medium))
    .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))

    Text(self.claimUrl(code))
      .font(.system(size: 20, weight: .semibold, design: .monospaced))
      .minimumScaleFactor(0.7)
      .lineLimit(1)
      .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
      .frame(maxWidth: .infinity, alignment: .center)
      .padding(.vertical, 8)
  }

  @ViewBuilder private var loadingContent: some View {
    ProgressView()
      .scaleEffect(1.3)
      .tint(Color(self.cs, light: .violet500, dark: .violet400))
      .frame(maxWidth: .infinity, alignment: .center)

    Text(lstr(.claimCodeGenerating))
      .font(.system(size: 16, weight: .medium))
      .foregroundStyle(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
      .frame(maxWidth: .infinity, alignment: .center)
  }

  @ViewBuilder private var errorContent: some View {
    Text(lstr(.claimCodeErrorTitle))
      .font(.system(size: 20, weight: .bold))
      .frame(maxWidth: .infinity, alignment: .center)
      .multilineTextAlignment(.center)

    Text(lstr(.claimCodeErrorBody))
      .font(.system(size: 16, weight: .medium))
      .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
      .frame(maxWidth: .infinity, alignment: .center)
      .multilineTextAlignment(.center)
  }

  private func codeString(_ code: Int) -> String {
    String(format: "%06d", code)
  }

  private func claimUrl(_ code: Int) -> String {
    "https://gertrude.app/a/\(self.codeString(code))"
  }
}

#Preview("Polling") {
  ClaimCodeView(
    code: 123_456,
    dismissLabel: "Cancel",
    deviceType: "iPhone",
    statusDelay: .seconds(2),
  )
}

#Preview("Polling (Dark)") {
  ClaimCodeView(
    code: 123_456,
    dismissLabel: "Skip for now",
    deviceType: "iPad",
    statusDelay: .seconds(2),
  )
  .preferredColorScheme(.dark)
}

#Preview("Loading") {
  ClaimCodeView(code: nil, dismissLabel: "Cancel", deviceType: "iPhone")
}

#Preview("Error") {
  ClaimCodeView(code: nil, failed: true, dismissLabel: "Cancel", deviceType: "iPhone")
}
