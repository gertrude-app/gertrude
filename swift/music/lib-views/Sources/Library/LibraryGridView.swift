import SwiftUI

struct LibraryGridView: View {
  @State private var selectedArtistID: String?

  private let albums: [AlbumData]
  private let artists: [ArtistData]
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let currentTrackID: String?
  private let playbackQueueTrackIDs: [String]
  private let isPlaybackLoading: Bool
  private let isPlaybackPlaying: Bool
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onArtistPlayTap: @MainActor @Sendable (String) -> Void
  private let onArtistSongTap: @MainActor @Sendable (String, String) -> Void
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  init(
    albums: [AlbumData],
    artists: [ArtistData] = [],
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    currentTrackID: String? = nil,
    playbackQueueTrackIDs: [String] = [],
    isPlaybackLoading: Bool = false,
    isPlaybackPlaying: Bool = false,
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistPlayTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistSongTap: @MainActor @escaping @Sendable (String, String) -> Void = { _, _ in },
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.albums = albums
    self.artists = artists
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
    self.currentTrackID = currentTrackID
    self.playbackQueueTrackIDs = playbackQueueTrackIDs
    self.isPlaybackLoading = isPlaybackLoading
    self.isPlaybackPlaying = isPlaybackPlaying
    self.onAlbumTap = onAlbumTap
    self.onArtistPlayTap = onArtistPlayTap
    self.onArtistSongTap = onArtistSongTap
    self.onDebugResetTap = onDebugResetTap
  }

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        if self.isLoading {
          self.loadingGrid(containerWidth: proxy.size.width)
        } else if self.albums.isEmpty, self.artists.isEmpty {
          LibraryGridEmptyStateView()
            .padding(.horizontal, self.horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, self.bottomContentPadding)
        } else {
          self.libraryGrid(containerWidth: proxy.size.width)

          #if DEBUG
            if let onDebugResetTap = self.onDebugResetTap {
              DebugResetOnboardingButton(onTap: onDebugResetTap)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, self.horizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, self.bottomContentPadding)
            }
          #endif
        }
      }
      .background(.background)
      .navigationDestination(for: ArtistData.self) { artist in
        ArtistDetailView(
          artist: ArtistDetailData(artist: artist),
          topSongs: artist.topSongs,
          releases: self.releases(for: artist),
          currentTrackID: self.currentTrackID(for: artist),
          isPlaying: self.isPlaybackPlaying(for: artist),
          isLoading: self.isPlaybackLoading(for: artist),
          onPlayTap: { self.onArtistPlayTap(artist.id) },
          onSongTap: { self.onArtistSongTap(artist.id, $0) },
          onReleaseTap: self.onAlbumTap,
        )
      }
    }
    .artistDetailZoomPush(
      artist: self.selectedArtist,
      releases: self.selectedArtistReleases,
      currentTrackID: self.selectedArtist.flatMap { self.currentTrackID(for: $0) },
      isPlaying: self.selectedArtist.map { self.isPlaybackPlaying(for: $0) } ?? false,
      isLoading: self.selectedArtist.map { self.isPlaybackLoading(for: $0) } ?? false,
      onPlayTap: self.onArtistPlayTap,
      onSongTap: self.onArtistSongTap,
      onReleaseTap: self.onAlbumTap,
      onDismiss: { artistID in
        if self.selectedArtistID == artistID {
          self.selectedArtistID = nil
        }
      },
    )
  }

  private let horizontalPadding: CGFloat = 20
  private let columnSpacing: CGFloat = 16

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(minimum: 148), spacing: self.columnSpacing, alignment: .top),
      count: 2,
    )
  }

  private func libraryGrid(containerWidth: CGFloat) -> some View {
    LazyVGrid(columns: self.columns, alignment: .leading, spacing: 24) {
      ForEach(self.artists) { artist in
        Group {
          #if os(iOS)
            Button {
              self.selectedArtistID = artist.id
            } label: {
              ArtistCardView(
                artist: artist,
                artworkSize: self.artworkSize(for: containerWidth),
              )
            }
          #else
            NavigationLink(value: artist) {
              ArtistCardView(
                artist: artist,
                artworkSize: self.artworkSize(for: containerWidth),
              )
            }
          #endif
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      ForEach(self.albums) { album in
        AlbumCardView(
          album: album,
          artworkSize: self.artworkSize(for: containerWidth),
          transitionNamespace: self.transitionNamespace,
        ) {
          self.onAlbumTap(album.id)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(.horizontal, self.horizontalPadding)
    .padding(.top, 16)
    .padding(.bottom, self.albumGridBottomPadding)
  }

  private var selectedArtist: ArtistData? {
    guard let selectedArtistID else { return nil }
    return self.artists.first { $0.id == selectedArtistID }
  }

  private var selectedArtistReleases: [ArtistReleaseData] {
    guard let selectedArtist else { return [] }
    return self.releases(for: selectedArtist)
  }

  private func releases(for artist: ArtistData) -> [ArtistReleaseData] {
    let releaseAlbumIds = Set(artist.releaseAlbumIds)
    return self.albums.compactMap { album in
      let belongsToArtist = releaseAlbumIds.isEmpty
        ? album.artist.localizedCaseInsensitiveContains(artist.name)
        : releaseAlbumIds.contains(album.id)
      guard belongsToArtist else { return nil }
      return ArtistReleaseData(
        id: album.id,
        title: album.title,
        artist: album.artist,
        artworkUrl: album.artworkUrl,
        artworkPalette: album.artworkPalette,
        releaseDate: album.releaseDate,
        trackCount: album.trackCount,
        releaseType: album.releaseType,
      )
    }
  }

  private func currentTrackID(for artist: ArtistData) -> String? {
    self.isCurrentQueue(for: artist) ? self.currentTrackID : nil
  }

  private func isPlaybackLoading(for artist: ArtistData) -> Bool {
    self.isPlaybackLoading && self.isCurrentQueue(for: artist)
  }

  private func isPlaybackPlaying(for artist: ArtistData) -> Bool {
    self.isPlaybackPlaying && self.isCurrentQueue(for: artist)
  }

  private func isCurrentQueue(for artist: ArtistData) -> Bool {
    !artist.topSongs.isEmpty
      && artist.topSongs.map(\.id) == self.playbackQueueTrackIDs
  }

  private func loadingGrid(containerWidth: CGFloat) -> some View {
    LazyVGrid(columns: self.columns, alignment: .leading, spacing: 24) {
      ForEach(0 ..< 6, id: \.self) { _ in
        VStack(alignment: .leading, spacing: 10) {
          SkeletonBlock(
            width: self.artworkSize(for: containerWidth),
            height: self.artworkSize(for: containerWidth),
            cornerRadius: 20,
          )

          VStack(alignment: .leading, spacing: 6) {
            SkeletonBlock(width: 132, height: 13, cornerRadius: 6)
            SkeletonBlock(width: 92, height: 11, cornerRadius: 5)
          }
        }
        .frame(width: self.artworkSize(for: containerWidth), alignment: .leading)
      }
    }
    .padding(.horizontal, self.horizontalPadding)
    .padding(.top, 16)
    .padding(.bottom, self.bottomContentPadding)
    .accessibilityLabel("Loading library")
  }

  private let bottomContentPadding: CGFloat = 96

  private var albumGridBottomPadding: CGFloat {
    #if DEBUG
      self.onDebugResetTap == nil ? self.bottomContentPadding : 8
    #else
      self.bottomContentPadding
    #endif
  }

  private func artworkSize(for containerWidth: CGFloat) -> CGFloat {
    max(148, floor((containerWidth - self.horizontalPadding * 2 - self.columnSpacing) / 2))
  }
}

#if DEBUG
  private struct DebugResetOnboardingButton: View {
    let onTap: @MainActor @Sendable () -> Void

    var body: some View {
      Button("Reset onboarding", action: self.onTap)
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .buttonStyle(.bordered)
        .tint(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
    }
  }
#endif

private struct LibraryGridEmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "rectangle.stack")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(.secondary)

      Text("No music yet")
        .font(.system(size: 18, weight: .semibold))

      Text("Approved artists and albums will show up here.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
  }
}

#if DEBUG
  #Preview("Library grid") {
    LibraryGridView(albums: .previewAlbums, artists: .previewArtists, onDebugResetTap: {})
  }

  #Preview("Library grid empty") {
    LibraryGridView(albums: [])
  }
#endif
