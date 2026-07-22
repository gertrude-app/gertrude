import SwiftUI

public struct MusicAppConnectionView: View {
  public enum State: Equatable, Sendable {
    case checking
    case unclaimed(code: Int)
    case failed
  }

  private let state: State
  private let onRetryTap: @MainActor @Sendable () -> Void

  public init(
    state: State,
    onRetryTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.state = state
    self.onRetryTap = onRetryTap
  }

  public var body: some View {
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
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
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

    case .unclaimed(let code):
      let claimLink = MusicClaimLink(code: code)
      VStack(spacing: 16) {
        Text(claimLink.codeString)
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

          Text(claimLink.displayURL)
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

        ShareLink(item: claimLink.url) {
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
      "Connect with account owner"
    case .failed:
      "Couldn’t connect"
    }
  }

  private var message: String {
    switch self.state {
    case .checking:
      "We’re checking whether this device is connected to a Gertrude account."
    case .unclaimed:
      "Send this link to the Gertrude account owner so they can connect this device in the dashboard."
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
}

#Preview("Claim code") {
  MusicAppConnectionView(
    state: .unclaimed(code: 123_456),
    onRetryTap: {},
  )
}

#Preview("Checking") {
  MusicAppConnectionView(state: .checking, onRetryTap: {})
}

#Preview("Failed") {
  MusicAppConnectionView(state: .failed, onRetryTap: {})
}
