import SwiftUI

public struct AlbumCardView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let album: AlbumData
  private let artworkSize: CGFloat
  private let transitionNamespace: Namespace.ID?
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onTap: @MainActor @Sendable () -> Void

  public init(
    album: AlbumData,
    artworkSize: CGFloat = 148,
    transitionNamespace: Namespace.ID? = nil,
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.album = album
    self.artworkSize = artworkSize
    self.transitionNamespace = transitionNamespace
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

        VStack(alignment: .leading, spacing: 2) {
          Text(self.album.title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color(self.colorScheme, light: .black, dark: .white))
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          Text(self.album.artist)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(
              self.colorScheme,
              light: .black.opacity(0.8),
              dark: .white.opacity(0.72),
            ))
            .lineLimit(1)
        }
      }
      .frame(width: self.artworkSize, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .playbackQueueContextMenu(
      onPlayNext: self.onPlayNext,
      onAddToQueue: self.onAddToQueue,
    )
    .accessibilityLabel("\(self.album.title), \(self.album.artist)")
  }

  private var artworkTransitionID: String {
    albumArtworkZoomTransitionID(for: self.album.id)
  }
}

#if DEBUG
  #Preview("Album cards") {
    HStack(alignment: .top, spacing: 16) {
      AlbumCardView(album: [AlbumData].previewAlbums[0])
      AlbumCardView(album: [AlbumData].previewAlbums[1])
    }
    .padding(24)
  }
#endif
