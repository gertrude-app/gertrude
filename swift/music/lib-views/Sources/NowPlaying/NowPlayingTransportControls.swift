import SwiftUI

struct NowPlayingTransportControls: View {
  let isPlaying: Bool
  let isLoading: Bool
  let onPlayPauseTap: @MainActor @Sendable () -> Void
  let onPreviousTap: @MainActor @Sendable () -> Void
  let onNextTap: @MainActor @Sendable () -> Void

  var body: some View {
    HStack(spacing: 34) {
      NowPlayingSecondaryControlButton(
        systemName: "backward.fill",
        accessibilityLabel: "Previous",
        action: self.onPreviousTap,
      )

      Button(action: self.onPlayPauseTap) {
        Group {
          if self.isLoading {
            ProgressView()
              .controlSize(.large)
              .tint(.white)
          } else {
            Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
              .font(.system(size: 42, weight: .black))
              .nowPlayingPlayPauseSymbolTransition(value: self.isPlaying)
          }
        }
        .foregroundStyle(.white)
        .frame(width: 58, height: 58)
        .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(self.isLoading)
      .accessibilityLabel(
        self.isLoading ? "Loading" : self.isPlaying ? "Pause" : "Play",
      )

      NowPlayingSecondaryControlButton(
        systemName: "forward.fill",
        accessibilityLabel: "Next",
        action: self.onNextTap,
      )
    }
  }
}

private extension View {
  @ViewBuilder
  func nowPlayingPlayPauseSymbolTransition(value: Bool) -> some View {
    if #available(iOS 18.0, macOS 15.0, *) {
      self
        .contentTransition(
          .symbolEffect(
            .replace.magic(fallback: .replace),
            options: .speed(2.2),
          ),
        )
        .animation(.easeInOut(duration: 0.12), value: value)
    } else {
      self
        .contentTransition(
          .symbolEffect(.replace, options: .speed(2.2)),
        )
        .animation(.easeInOut(duration: 0.12), value: value)
    }
  }
}

private struct NowPlayingSecondaryControlButton: View {
  let systemName: String
  let accessibilityLabel: String
  let action: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.action) {
      Image(systemName: self.systemName)
        .font(.system(size: 27, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 58, height: 58)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
  }
}
