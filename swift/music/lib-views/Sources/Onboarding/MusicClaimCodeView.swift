import GertieUI
import SwiftUI

struct MusicClaimCodeView: View {
  @Environment(\.colorScheme) private var colorScheme

  let code: Int
  let audience: MusicClaimAudience
  let statusDelay: Duration

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: "link.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.colorScheme, light: .violet500, dark: .violet400))
        .accessibilityHidden(true)
        .frame(maxWidth: .infinity, alignment: .center)

      Spacer()
      Spacer()

      GertieWaitingStatus(label: "Waiting for account connection…", delay: self.statusDelay)

      Spacer()

      Text(self.instructions)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(Color(
          self.colorScheme,
          light: .black.opacity(0.8),
          dark: .white.opacity(0.8),
        ))
        .fixedSize(horizontal: false, vertical: true)

      Text(self.claimLink.url.absoluteString)
        .font(.system(size: 20, weight: .semibold, design: .monospaced))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .foregroundStyle(Color(self.colorScheme, light: .violet600, dark: .violet300))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .textSelection(.enabled)

      ShareLink(item: self.claimLink.url.absoluteString) {
        HStack(spacing: 8) {
          Text("Send link")
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

  init(
    code: Int,
    audience: MusicClaimAudience,
    statusDelay: Duration = .seconds(45),
  ) {
    self.code = code
    self.audience = audience
    self.statusDelay = statusDelay
  }

  private var instructions: String {
    switch self.audience {
    case .parentPartner:
      "Open this link on your own phone or computer (not this \(musicDeviceType())) to connect a Gertrude account:"
    case .selfManagement:
      "Send this link to your parent or accountability partner so they can connect this device to their Gertrude account:"
    }
  }

  private var claimLink: MusicClaimLink {
    MusicClaimLink(code: self.code)
  }
}

#Preview("Claim (Parent)") {
  MusicClaimCodeView(code: 123_456, audience: .parentPartner, statusDelay: .seconds(2))
}

#Preview("Claim (Self)") {
  MusicClaimCodeView(code: 123_456, audience: .selfManagement, statusDelay: .seconds(2))
}

#Preview("Claim Dark") {
  MusicClaimCodeView(code: 123_456, audience: .parentPartner, statusDelay: .seconds(2))
    .preferredColorScheme(.dark)
}
