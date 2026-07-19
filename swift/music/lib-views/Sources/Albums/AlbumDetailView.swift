import SwiftUI

public struct AlbumDetailView: View {
  private let album: AlbumData
  private let rows: [AlbumDetailTrackRow]
  private let isPlaying: Bool
  private let isLoading: Bool
  private let isLoadingTracks: Bool
  private let currentTrackID: String?
  private let onAddToPlaylist: @MainActor @Sendable () -> Void
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onPlayTap: @MainActor @Sendable () -> Void
  private let onTrackAddToPlaylist: @MainActor @Sendable (String) -> Void
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
    onAddToPlaylist: @MainActor @escaping @Sendable () -> Void = {},
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
    onTrackAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.album = album
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.isLoadingTracks = isLoadingTracks
    self.currentTrackID = currentTrackID
    self.onAddToPlaylist = onAddToPlaylist
    self.onAddToQueue = onAddToQueue
    self.onPlayNext = onPlayNext
    self.onPlayTap = onPlayTap
    self.onTrackAddToPlaylist = onTrackAddToPlaylist
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
        self.heroContent(containerWidth: proxy.size.width)
          .frame(maxWidth: .infinity)
          .padding(.top, proxy.safeAreaInsets.top + 18)
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
          .frame(maxWidth: 600)
          .frame(maxWidth: .infinity)
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
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
            .playbackQueueContextMenu(
              onPlayNext: { self.onTrackPlayNext(row.track.id) },
              onAddToQueue: { self.onTrackAddToQueue(row.track.id) },
              onAddToPlaylist: { self.onTrackAddToPlaylist(row.track.id) },
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
    .toolbar {
      ToolbarItem(placement: self.menuPlacement) {
        Menu {
          Button(action: self.onPlayNext) {
            Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
          }
          .tint(.primary)

          Button(action: self.onAddToQueue) {
            Label("Add to Queue", systemImage: "text.badge.plus")
          }
          .tint(.primary)

          Button(action: self.onAddToPlaylist) {
            Label("Add to Playlist", systemImage: "music.note.list")
          }
          .tint(.primary)
        } label: {
          Label("Album Actions", systemImage: "ellipsis")
        }
        .tint(.primary)
        .disabled(self.rows.isEmpty)
      }
    }
  }

  private var menuPlacement: ToolbarItemPlacement {
    #if os(iOS)
      .topBarTrailing
    #else
      .automatic
    #endif
  }

  @ViewBuilder
  private func heroContent(containerWidth: CGFloat) -> some View {
    if containerWidth >= 800 {
      let artworkSize = min(300, max(220, (containerWidth - 96) * 0.38))
      HStack(spacing: 36) {
        AlbumArtworkView(
          album: self.album,
          size: artworkSize,
          cornerRadius: 16,
        )

        VStack(spacing: 18) {
          self.albumMetadata

          self.playButton
            .frame(maxWidth: 440)
        }
        .frame(maxWidth: 440)
      }
      .frame(maxWidth: 900)
      .padding(.horizontal, 32)
    } else {
      VStack(spacing: 16) {
        AlbumArtworkView(
          album: self.album,
          size: self.artworkSize(for: containerWidth),
          cornerRadius: 16,
        )

        self.albumMetadata
          .frame(maxWidth: 560)
          .padding(.horizontal, 28)

        self.playButton
          .frame(maxWidth: 520)
          .padding(.horizontal, 20)
          .padding(.top, 4)
      }
    }
  }

  private var albumMetadata: some View {
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
  }

  private var playButton: some View {
    AlbumDetailPlayButton(
      isPlaying: self.isPlaying,
      isLoading: self.isLoading,
      palette: self.album.artworkPalette,
      onTap: self.onPlayTap,
    )
  }

  private func artworkSize(for containerWidth: CGFloat) -> CGFloat {
    max(1, min(320, containerWidth - 64))
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

  #Preview("Album detail narrow") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: .previewTracks,
      )
    }
    .frame(width: 320, height: 568)
  }

  #Preview("Album detail wide") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: .previewTracks,
      )
    }
    .frame(width: 1024, height: 768)
  }

  #Preview("Album detail accessibility text") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: .previewTracks,
      )
    }
    .environment(\.dynamicTypeSize, .accessibility3)
    .frame(width: 600, height: 700)
  }
#endif
