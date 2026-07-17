import SwiftUI

struct ArtistDetailHeroView: View {
  @Environment(\.self) private var environment

  let artist: ArtistDetailData
  let isPlaying: Bool
  let isLoading: Bool
  let onPlayTap: @MainActor @Sendable () -> Void

  var body: some View {
    let colors = PlaybackButtonColors(
      palette: self.artist.artworkPalette,
      environment: self.environment,
    )

    VStack(spacing: 18) {
      ArtistArtworkView(
        artworkUrl: self.artist.artworkUrl,
        size: 220,
      )

      Text(self.artist.name)
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .multilineTextAlignment(.center)
        .lineLimit(3)

      Button(action: self.onPlayTap) {
        HStack(spacing: 9) {
          if self.isLoading {
            ProgressView()
              .controlSize(.small)
              .tint(colors.foreground)
          } else {
            Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
              .font(.system(size: 15, weight: .bold))
          }

          Text("\(self.isPlaying ? "Playing" : "Play") \(self.artist.name)")
            .font(.headline)
            .lineLimit(1)
        }
        .foregroundStyle(colors.foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(colors.background, in: .capsule)
      }
      .buttonStyle(.plain)
      .disabled(self.isLoading)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .contain)
  }
}
