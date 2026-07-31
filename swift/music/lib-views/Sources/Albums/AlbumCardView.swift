import SwiftUI

public struct AlbumCardView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let album: AlbumData
  private let artworkSize: CGFloat
  private let isPlaying: Bool
  private let transitionNamespace: Namespace.ID?
  private let onAddToPlaylist: @MainActor @Sendable () -> Void
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onTap: @MainActor @Sendable () -> Void

  public init(
    album: AlbumData,
    artworkSize: CGFloat = 148,
    isPlaying: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onAddToPlaylist: @MainActor @escaping @Sendable () -> Void = {},
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.album = album
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
        AlbumArtworkView(
          album: self.album,
          size: self.artworkSize,
        )
        .matchedTransitionSourceIfAvailable(
          id: self.artworkTransitionID,
          in: self.transitionNamespace,
          cornerRadius: 12,
        )

        LibraryCardMetadataView(
          title: self.album.title,
          subtitle: self.album.artist,
          isPlaying: self.isPlaying,
          titleColor: Color(self.colorScheme, light: .black, dark: .white),
          subtitleColor: Color(
            self.colorScheme,
            light: .black.opacity(0.8),
            dark: .white.opacity(0.72),
          ),
        )
      }
      .frame(width: self.artworkSize, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .playbackQueueContextMenu(
      onPlayNext: self.onPlayNext,
      onAddToQueue: self.onAddToQueue,
      onAddToPlaylist: self.onAddToPlaylist,
    )
    .accessibilityLabel(
      "\(self.isPlaying ? "Playing, " : "")\(self.album.title), \(self.album.artist)",
    )
  }

  private var artworkTransitionID: String {
    albumArtworkZoomTransitionID(for: self.album.id)
  }
}

#if DEBUG
  #Preview("Album cards") {
    HStack(alignment: .top, spacing: 16) {
      AlbumCardView(album: [AlbumData].previewAlbums[0])
      AlbumCardView(album: [AlbumData].previewAlbums[1], isPlaying: true)
    }
    .padding(24)
  }
#endif
