import SwiftUI

struct MusicClaimCodeView: View {
  @Environment(\.colorScheme) private var colorScheme

  let code: Int
  let statusDelay: Duration
  let onRefreshTap: @MainActor @Sendable () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: "link.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.colorScheme, light: .violet500, dark: .violet400))
        .frame(maxWidth: .infinity, alignment: .center)

      Spacer()
      Spacer()

      WaitingStatus(label: "Watching for account connection…", delay: self.statusDelay)

      Spacer()

      Text(
        "Send this link to the Gertrude account owner so they can connect this device in the dashboard.",
      )
      .font(.system(size: 17, weight: .medium))
      .foregroundStyle(Color(
        self.colorScheme,
        light: .black.opacity(0.8),
        dark: .white.opacity(0.8),
      ))
      .fixedSize(horizontal: false, vertical: true)

      Text(self.claimUrl)
        .font(.system(size: 20, weight: .semibold, design: .monospaced))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .foregroundStyle(Color(self.colorScheme, light: .violet600, dark: .violet300))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .textSelection(.enabled)

      BigButton(
        "I claimed this device",
        type: .button { self.onRefreshTap() },
        variant: .secondary,
      )

      BigButton(
        "Send link",
        type: .share(self.claimUrl),
        variant: .primary,
        icon: "square.and.arrow.up",
      )
    }
    .frame(maxWidth: 500)
    .padding(30)
    .padding(.top, 50)
    .screenGradientBackground()
  }

  init(
    code: Int,
    statusDelay: Duration = .seconds(45),
    onRefreshTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.code = code
    self.statusDelay = statusDelay
    self.onRefreshTap = onRefreshTap
  }

  private var codeString: String {
    String(format: "%06d", self.code)
  }

  private var claimUrl: String {
    "https://gertrude.app/m/\(self.codeString)"
  }
}

#Preview("Claim") {
  MusicClaimCodeView(code: 123_456, statusDelay: .seconds(2))
}

#Preview("Claim Dark") {
  MusicClaimCodeView(code: 123_456, statusDelay: .seconds(2))
    .preferredColorScheme(.dark)
}
