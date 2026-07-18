import SwiftUI

struct AlbumDetailPlayButton: View {
  @Environment(\.self) private var environment

  let isPlaying: Bool
  let isLoading: Bool
  let palette: ArtworkPalette?
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    let colors = PlaybackButtonColors(
      palette: self.palette,
      environment: self.environment,
    )

    Button(action: self.onTap) {
      HStack(spacing: 8) {
        if self.isLoading {
          ProgressView()
            .controlSize(.small)
            .tint(colors.foreground)
        } else {
          Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
        }

        Text(self.title)
      }
      .font(.system(size: 17, weight: .bold, design: .rounded))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .frame(minHeight: 52)
      .foregroundStyle(colors.foreground)
      .background(colors.background, in: Capsule())
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .disabled(self.isLoading)
  }

  private var title: String {
    if self.isLoading { return "Loading" }
    return self.isPlaying ? "Playing" : "Play"
  }
}
