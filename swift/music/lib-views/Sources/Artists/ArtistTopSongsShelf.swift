import SwiftUI

struct ArtistTopSongsShelf: View {
  let songs: [ArtistTopSongData]
  let currentTrackID: String?
  let isPlaying: Bool
  let onSongAddToQueue: @MainActor @Sendable (String) -> Void
  let onSongPlayNext: @MainActor @Sendable (String) -> Void
  let onSongTap: @MainActor @Sendable (String) -> Void

  @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 52

  private var rows: [GridItem] {
    Array(
      repeating: GridItem(.fixed(self.rowHeight), spacing: 8, alignment: .top),
      count: 3,
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ArtistDetailSectionHeader(title: "Top Songs")

      if self.songs.isEmpty {
        ArtistDetailEmptyCard(
          systemImage: "music.note.list",
          title: "Top songs will appear here",
          message: "We’ll show a short Apple Music queue for artist playback.",
        )
        .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHGrid(rows: self.rows, alignment: .top, spacing: 40) {
            ForEach(
              Array(self.songs.enumerated()),
              id: \.element.id,
            ) { index, song in
              ArtistTopSongCard(
                number: index + 1,
                song: song,
                isCurrent: song.id == self.currentTrackID,
                isPlaying: self.isPlaying,
                onTap: { self.onSongTap(song.id) },
              )
              .playbackQueueContextMenu(
                onPlayNext: { self.onSongPlayNext(song.id) },
                onAddToQueue: { self.onSongAddToQueue(song.id) },
              )
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
      }
    }
  }
}

private struct ArtistTopSongCard: View {
  @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 292
  @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 52

  let number: Int
  let song: ArtistTopSongData
  let isCurrent: Bool
  let isPlaying: Bool
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 0) {
        Text(self.number, format: .number)
          .font(.caption.weight(.bold))
          .monospacedDigit()
          .foregroundStyle(.secondary)

        ArtistDetailArtworkThumbnail(
          url: self.song.artworkUrl,
          systemImage: "music.note",
          size: 38,
        )
        .padding(.trailing, 8)
        .padding(.leading, 8)

        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 5) {
            if self.isCurrent {
              ArtistTopSongWaveformView(isPlaying: self.isPlaying)
            }

            Text(self.song.title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(
                self.isCurrent ? Color.gertrudeBrandAccent : .primary,
              )
              .lineLimit(1)
          }

          if let detailText = self.song.albumTitle?.nonEmpty {
            Text(detailText)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 8)

        if let duration = self.song.duration?.nonEmpty {
          Text(duration)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: self.cardWidth, height: self.cardHeight, alignment: .leading)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
  }

  private var accessibilityLabel: String {
    [
      self.isCurrent ? self.isPlaying ? "Playing" : "Paused" : nil,
      "Song \(self.number)", self.song.title, self.song.artist,
      self.song.albumTitle,
    ]
    .compactMap { $0?.nonEmpty }
    .joined(separator: ", ")
  }
}

private struct ArtistTopSongWaveformView: View {
  let isPlaying: Bool

  @ScaledMetric(relativeTo: .subheadline) private var barSpacing: CGFloat = 1.5
  @ScaledMetric(relativeTo: .subheadline) private var barWidth: CGFloat = 2.25
  @ScaledMetric(relativeTo: .subheadline) private var minimumBarHeight: CGFloat = 3
  @ScaledMetric(relativeTo: .subheadline) private var waveformHeight: CGFloat = 12
  @ScaledMetric(relativeTo: .subheadline) private var waveformWidth: CGFloat = 10

  var body: some View {
    PlaybackWaveformView(
      isPlaying: self.isPlaying,
      color: .gertrudeBrandAccent,
      barCount: 3,
      barWidth: self.barWidth,
      barSpacing: self.barSpacing,
      minimumBarHeight: self.minimumBarHeight,
      maximumBarHeight: self.waveformHeight,
      containerWidth: self.waveformWidth,
      containerHeight: self.waveformHeight,
      alignment: .bottom,
      phaseStep: 1.15,
      minimumInterval: 1.0 / 15.0,
    )
  }
}
