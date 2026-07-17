import SwiftUI

public struct AlbumDetailView: View {
  private let album: AlbumData
  private let rows: [AlbumDetailTrackRow]
  private let isPlaying: Bool
  private let isLoading: Bool
  private let isLoadingTracks: Bool
  private let currentTrackID: String?
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onPlayTap: @MainActor @Sendable () -> Void
  private let onTrackAddToQueue: @MainActor @Sendable (String) -> Void
  private let onTrackPlayNext: @MainActor @Sendable (String) -> Void
  private let onTrackTap: @MainActor @Sendable (String) -> Void

  public init(
    album: AlbumData,
    tracks: [TrackData],
    isPlaying: Bool = false,
    isLoading: Bool = false,
    isLoadingTracks: Bool = false,
    currentTrackID: String? = nil,
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
    onTrackAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.album = album
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.isLoadingTracks = isLoadingTracks
    self.currentTrackID = currentTrackID
    self.onAddToQueue = onAddToQueue
    self.onPlayNext = onPlayNext
    self.onPlayTap = onPlayTap
    self.onTrackAddToQueue = onTrackAddToQueue
    self.onTrackPlayNext = onTrackPlayNext
    self.onTrackTap = onTrackTap
    self.rows = tracks.enumerated().map { index, track in
      AlbumDetailTrackRow(number: index + 1, track: track)
    }
  }

  public var body: some View {
    GeometryReader { proxy in
      List {
        VStack(spacing: 16) {
          AlbumArtworkView(
            album: self.album,
            size: self.artworkSize(for: proxy.size.width),
            cornerRadius: 16,
          )

          VStack(spacing: 5) {
            Text(self.album.title)
              .font(
                .system(
                  size: 26,
                  weight: .bold,
                  design: .rounded,
                ),
              )
              .foregroundStyle(.primary)
              .multilineTextAlignment(.center)
              .lineLimit(3)

            Text(self.album.artist)
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .lineLimit(2)
          }
          .padding(.horizontal, 28)

          AlbumDetailPlayButton(
            isPlaying: self.isPlaying,
            isLoading: self.isLoading,
            palette: self.album.artworkPalette,
            onTap: self.onPlayTap,
          )
          .playbackQueueContextMenu(
            onPlayNext: self.onPlayNext,
            onAddToQueue: self.onAddToQueue,
          )
          .padding(.horizontal, 20)
          .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, proxy.frame(in: .global).minY + 18)
        .padding(.bottom, 24)
        .background {
          if let backgroundColor = self.album.artworkPalette?.backgroundColor {
            LinearGradient(
              colors: [
                .clear,
                backgroundColor.opacity(0.3),
              ],
              startPoint: .top,
              endPoint: .bottom,
            )
            .ignoresSafeArea(edges: .top)
          }
        }
        .padding(.bottom, 30)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

        if self.rows.isEmpty {
          AlbumDetailEmptyTracksView(
            isLoading: self.isLoadingTracks,
          )
          .padding(.horizontal, 20)
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        } else {
          ForEach(self.rows) { row in
            AlbumDetailTrackRowView(
              row: row,
              isCurrent: row.track.id == self.currentTrackID,
              isPlaying: self.isPlaying && row.track.id == self.currentTrackID,
              palette: self.album.artworkPalette,
              onTap: { self.onTrackTap(row.track.id) },
            )
            .playbackQueueContextMenu(
              onPlayNext: { self.onTrackPlayNext(row.track.id) },
              onAddToQueue: { self.onTrackAddToQueue(row.track.id) },
            )
            .swipeActions(edge: .trailing) {
              Button {
                self.onTrackAddToQueue(row.track.id)
              } label: {
                Label("Add to Queue", systemImage: "text.badge.plus")
                  .labelStyle(.iconOnly)
              }
              .tint(Color.gertrudeBrandAccent)
              .accessibilityLabel("Add to Queue")
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
        }

        Color.clear
          .frame(height: 112)
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .accessibilityHidden(true)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(.background)
      .ignoresSafeArea(edges: .top)
    }
    .navigationTitle("")
    .detailNavigationBarBackground()
  }

  private func artworkSize(for containerWidth: CGFloat) -> CGFloat {
    min(320, max(220, containerWidth - 96))
  }
}

#if DEBUG
  #Preview("Album detail") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: .previewTracks,
      )
    }
  }

  #Preview("Album detail playing") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: .previewTracks,
        isPlaying: true,
        currentTrackID: [TrackData].previewTracks[2].id,
      )
    }
  }

  #Preview("Album detail loading tracks") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: [],
        isLoading: true,
        isLoadingTracks: true,
      )
    }
  }
#endif
