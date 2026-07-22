import SwiftUI

public struct PlaylistCardView: View {
  private let playlist: PlaylistData
  private let artworkSize: CGFloat
  private let transitionNamespace: Namespace.ID?
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onTap: @MainActor @Sendable () -> Void

  public init(
    playlist: PlaylistData,
    artworkSize: CGFloat = 148,
    transitionNamespace: Namespace.ID? = nil,
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.playlist = playlist
    self.artworkSize = artworkSize
    self.transitionNamespace = transitionNamespace
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

        VStack(alignment: .leading, spacing: 2) {
          Text(self.playlist.name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          Text(self.trackCountText)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      .frame(width: self.artworkSize, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .playbackQueueContextMenu(
      onPlayNext: self.playlist.entries.isEmpty ? nil : self.onPlayNext,
      onAddToQueue: self.playlist.entries.isEmpty ? nil : self.onAddToQueue,
    )
    .accessibilityLabel("\(self.playlist.name), \(self.trackCountText)")
  }

  private var trackCountText: String {
    self.playlist.trackCount == 1 ? "1 song" : "\(self.playlist.trackCount) songs"
  }
}
