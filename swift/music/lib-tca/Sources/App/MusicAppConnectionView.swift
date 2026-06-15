import SwiftUI

struct MusicAppConnectionView: View {
  enum State: Equatable {
    case checking
    case unclaimed(code: Int, expiresAt: Date)
    case failed
  }

  let state: State
  let onRetryTap: @MainActor @Sendable () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          self.icon
          self.textContent
          self.actionContent
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 72)
        .padding(.bottom, 96)
      }
      .background(.background)
      .navigationTitle("Gertrude Music")
    }
  }

  private var icon: some View {
    ZStack {
      Circle()
        .fill(.primary.opacity(0.06))
        .frame(width: 88, height: 88)

      Image(systemName: self.systemImage)
        .font(.system(size: 34, weight: .semibold))
        .foregroundStyle(.secondary)
    }
  }

  private var textContent: some View {
    VStack(spacing: 8) {
      Text(self.title)
        .font(.system(size: 26, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)

      Text(self.message)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder private var actionContent: some View {
    switch self.state {
    case .checking:
      ProgressView()
        .padding(.top, 8)

    case .unclaimed(let code, let expiresAt):
      let displayUrl = Self.displayClaimUrl(code)
      let shareUrl = URL(string: Self.claimUrl(code))!
      VStack(spacing: 16) {
        Text(Self.codeString(code))
          .font(.system(size: 44, weight: .black, design: .rounded))
          .monospacedDigit()
          .tracking(5)
          .foregroundStyle(.primary)
          .padding(.horizontal, 24)
          .padding(.vertical, 16)
          .background(.primary.opacity(0.06), in: .rect(cornerRadius: 22, style: .continuous))
          .textSelection(.enabled)

        VStack(spacing: 6) {
          Text("Parent link")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)

          Text(displayUrl)
            .font(.system(size: 17, weight: .semibold, design: .monospaced))
            .minimumScaleFactor(0.75)
            .lineLimit(1)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.primary.opacity(0.05), in: .rect(cornerRadius: 18, style: .continuous))

        Text("Expires \(expiresAt.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)

        ShareLink(item: shareUrl) {
          Label("Send link", systemImage: "square.and.arrow.up")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)

        Button("I claimed this device", action: self.onRetryTap)
          .buttonStyle(.borderedProminent)
      }
      .padding(.top, 8)

    case .failed:
      Button("Try again", action: self.onRetryTap)
        .buttonStyle(.borderedProminent)
        .padding(.top, 8)
    }
  }

  private var title: String {
    switch self.state {
    case .checking:
      "Checking connection"
    case .unclaimed:
      "Connect with a parent"
    case .failed:
      "Couldn’t connect"
    }
  }

  private var message: String {
    switch self.state {
    case .checking:
      "We’re checking whether this device is connected to a Gertrude parent account."
    case .unclaimed:
      "Send this link to a parent so they can connect this device in the Gertrude dashboard."
    case .failed:
      "Check your internet connection and try again."
    }
  }

  private var systemImage: String {
    switch self.state {
    case .checking:
      "music.note"
    case .unclaimed:
      "link.badge.plus"
    case .failed:
      "wifi.exclamationmark"
    }
  }

  private static func codeString(_ code: Int) -> String {
    String(format: "%06d", code)
  }

  private static func displayClaimUrl(_ code: Int) -> String {
    "gertrude.app/m/\(self.codeString(code))"
  }

  private static func claimUrl(_ code: Int) -> String {
    "https://\(self.displayClaimUrl(code))"
  }
}

#Preview("Claim code") {
  MusicAppConnectionView(
    state: .unclaimed(code: 123_456, expiresAt: .now + 900),
    onRetryTap: {},
  )
}

#Preview("Checking") {
  MusicAppConnectionView(state: .checking, onRetryTap: {})
}

#Preview("Failed") {
  MusicAppConnectionView(state: .failed, onRetryTap: {})
}
