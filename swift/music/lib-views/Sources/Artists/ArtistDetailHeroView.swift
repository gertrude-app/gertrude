import SwiftUI

struct ArtistDetailHeroView: View {
  @Environment(\.self) private var environment

  let artist: ArtistDetailData
  let containerWidth: CGFloat
  let isPlaying: Bool
  let isLoading: Bool
  let onPlayTap: @MainActor @Sendable () -> Void

  var body: some View {
    let colors = PlaybackButtonColors(
      palette: self.artist.artworkPalette,
      environment: self.environment,
    )

    Group {
      if self.containerWidth >= 800 {
        HStack(spacing: 36) {
          ArtistArtworkView(
            artworkUrl: self.artist.artworkUrl,
            size: min(280, max(220, (self.containerWidth - 96) * 0.36)),
          )

          VStack(spacing: 18) {
            self.artistName

            self.playButton(colors: colors)
              .frame(maxWidth: 440)
          }
          .frame(maxWidth: 440)
        }
        .frame(maxWidth: 900)
      } else {
        VStack(spacing: 18) {
          ArtistArtworkView(
            artworkUrl: self.artist.artworkUrl,
            size: max(1, min(220, self.containerWidth - 80)),
          )

          self.artistName

          self.playButton(colors: colors)
            .frame(maxWidth: 520)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .contain)
  }

  private var artistName: some View {
    Text(self.artist.name)
      .font(.system(.largeTitle, design: .rounded, weight: .bold))
      .multilineTextAlignment(.center)
      .lineLimit(3)
  }

  private func playButton(colors: PlaybackButtonColors) -> some View {
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
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
      .foregroundStyle(colors.foreground)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(colors.background, in: .capsule)
    }
    .buttonStyle(.plain)
    .disabled(self.isLoading)
  }
}
