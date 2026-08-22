import SwiftUI

public struct PlaylistCardView: View {
  private let playlist: PlaylistData
  private let artworkSize: CGFloat
  private let isPlaying: Bool
  private let transitionNamespace: Namespace.ID?
  private let onAddToPlaylist: @MainActor @Sendable () -> Void
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onTap: @MainActor @Sendable () -> Void

  public init(
    playlist: PlaylistData,
    artworkSize: CGFloat = 148,
    isPlaying: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onAddToPlaylist: @MainActor @escaping @Sendable () -> Void = {},
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.playlist = playlist
    self.artworkSize = artworkSize
    self.isPlaying = isPlaying
    self.transitionNamespace = transitionNamespace
    self.onAddToPlaylist = onAddToPlaylist
    self.onAddToQueue = onAddToQueue
    self.onPlayNext = onPlayNext
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: self.onTap) {
      VStack(alignment: .leading, spacing: 10) {
        PlaylistArtworkView(
          playlist: self.playlist,
          size: self.artworkSize,
        )
        .matchedTransitionSourceIfAvailable(
          id: playlistArtworkZoomTransitionID(for: self.playlist.id),
          in: self.transitionNamespace,
          cornerRadius: 12,
        )

        LibraryCardMetadataView(
          title: self.playlist.name,
          subtitle: self.trackCountText,
          isPlaying: self.isPlaying,
          titleColor: .primary,
          subtitleColor: .secondary,
        )
      }
      .frame(width: self.artworkSize, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .playbackQueueContextMenu(
      onPlayNext: self.playlist.entries.isEmpty ? nil : self.onPlayNext,
      onAddToQueue: self.playlist.entries.isEmpty ? nil : self.onAddToQueue,
      onAddToPlaylist: self.playlist.entries.isEmpty ? nil : self.onAddToPlaylist,
    )
    .accessibilityLabel(
      "\(self.isPlaying ? "Playing, " : "")\(self.playlist.name), \(self.trackCountText)",
    )
  }

  private var trackCountText: String {
    self.playlist.trackCount == 1 ? "1 song" : "\(self.playlist.trackCount) songs"
  }
}

#if DEBUG
  #Preview("Playlist card playing") {
    PlaylistCardView(
      playlist: .previewRoadTrip,
      isPlaying: true,
    )
    .padding(24)
  }
#endif
