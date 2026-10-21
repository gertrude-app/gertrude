import SwiftUI

public struct ArtistDetailView: View {
  private let artist: ArtistDetailData
  private let topSongs: [ArtistTopSongData]
  private let releases: [ArtistReleaseData]
  private let transitionNamespace: Namespace.ID?
  private let currentTrackID: String?
  private let isPlaying: Bool
  private let isLoading: Bool
  private let isCurrentTrackPlaying: Bool
  private let onAddToPlaylist: @MainActor @Sendable () -> Void
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onPlayTap: @MainActor @Sendable () -> Void
  private let onSongAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onSongAddToQueue: @MainActor @Sendable (String) -> Void
  private let onSongPlayNext: @MainActor @Sendable (String) -> Void
  private let onSongTap: @MainActor @Sendable (String) -> Void
  private let onReleaseAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onReleaseAddToQueue: @MainActor @Sendable (String) -> Void
  private let onReleasePlayNext: @MainActor @Sendable (String) -> Void
  private let onReleaseTap: @MainActor @Sendable (String) -> Void

  public init(
    artist: ArtistDetailData,
    topSongs: [ArtistTopSongData] = [],
    releases: [ArtistReleaseData] = [],
    transitionNamespace: Namespace.ID? = nil,
    currentTrackID: String? = nil,
    isPlaying: Bool = false,
    isLoading: Bool = false,
    isCurrentTrackPlaying: Bool = false,
    onAddToPlaylist: @MainActor @escaping @Sendable () -> Void = {},
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
    onSongAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onSongAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onSongPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onSongTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReleaseAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReleaseAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReleasePlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReleaseTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.artist = artist
    self.topSongs = topSongs
    self.releases = releases
    self.transitionNamespace = transitionNamespace
    self.currentTrackID = currentTrackID
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.isCurrentTrackPlaying = isCurrentTrackPlaying
    self.onAddToPlaylist = onAddToPlaylist
    self.onAddToQueue = onAddToQueue
    self.onPlayNext = onPlayNext
    self.onPlayTap = onPlayTap
    self.onSongAddToPlaylist = onSongAddToPlaylist
    self.onSongAddToQueue = onSongAddToQueue
    self.onSongPlayNext = onSongPlayNext
    self.onSongTap = onSongTap
    self.onReleaseAddToPlaylist = onReleaseAddToPlaylist
    self.onReleaseAddToQueue = onReleaseAddToQueue
    self.onReleasePlayNext = onReleasePlayNext
    self.onReleaseTap = onReleaseTap
  }

  public var body: some View {
    DetailContentLayout(artworkURL: self.artist.artworkUrl) { proxy, bookGeometry in
      self.scrollingContent(proxy: proxy, bookGeometry: bookGeometry)
    } hero: { width, maximumArtworkSize in
      self.heroContent(containerWidth: width, maximumArtworkSize: maximumArtworkSize)
    } content: {
      ScrollView {
        self.artistContent
          .padding(.bottom, 96)
      }
      .background(.background)
    }
    .navigationTitle("")
    .detailNavigationBarBackground()
    .toolbar {
      ToolbarItem(placement: .detailActions) {
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
          Label("Artist Actions", systemImage: "ellipsis")
        }
        .tint(.primary)
        .disabled(self.releases.isEmpty)
      }
    }
  }

  private func scrollingContent(
    proxy: GeometryProxy,
    bookGeometry: FoldedContentGeometry?,
  ) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 30) {
        Group {
          if let bookGeometry {
            BookDetailHero(geometry: bookGeometry) { size in
              ArtistArtworkView(artworkUrl: self.artist.artworkUrl, size: min(280, size))
            } metadata: {
              ArtistDetailMetadataView(
                artist: self.artist,
                isPlaying: self.isPlaying,
                isLoading: self.isLoading,
                onPlayTap: self.onPlayTap,
              )
              .frame(maxWidth: 440)
              .padding(.horizontal, 24)
            }
          } else {
            self.heroContent(containerWidth: proxy.size.width)
          }
        }
        .padding(.top, proxy.safeAreaInsets.top + 18)
        .padding(.bottom, 24)
        .anchorPreference(key: DetailHeroBoundsPreferenceKey.self, value: .bounds) { $0 }

        self.artistContent
      }
      .padding(.bottom, 96)
    }
    .detailHeroBackground(artworkURL: self.artist.artworkUrl)
    .background(.background)
    .ignoresSafeArea(edges: .top)
  }

  private func heroContent(
    containerWidth: CGFloat,
    maximumArtworkSize: CGFloat = 320,
  ) -> some View {
    ArtistDetailHeroView(
      artist: self.artist,
      containerWidth: containerWidth,
      isPlaying: self.isPlaying,
      isLoading: self.isLoading,
      onPlayTap: self.onPlayTap,
      maximumArtworkSize: maximumArtworkSize,
    )
    .padding(.horizontal, 20)
  }

  private var artistContent: some View {
    VStack(alignment: .leading, spacing: 30) {
      ArtistTopSongsShelf(
        songs: self.topSongs,
        currentTrackID: self.currentTrackID,
        isPlaying: self.isCurrentTrackPlaying,
        onSongAddToPlaylist: self.onSongAddToPlaylist,
        onSongAddToQueue: self.onSongAddToQueue,
        onSongPlayNext: self.onSongPlayNext,
        onSongTap: self.onSongTap,
      )

      ArtistReleasesShelf(
        releases: self.releases,
        transitionNamespace: self.transitionNamespace,
        onReleaseAddToPlaylist: self.onReleaseAddToPlaylist,
        onReleaseAddToQueue: self.onReleaseAddToQueue,
        onReleasePlayNext: self.onReleasePlayNext,
        onReleaseTap: self.onReleaseTap,
      )

      if let editorialNotes = self.artist.editorialNotes?.nonEmpty {
        ArtistEditorialNotesSection(notes: editorialNotes)
          .frame(maxWidth: 700)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 20)
      }
    }
  }
}

#if DEBUG
  #Preview("Artist detail") {
    NavigationStack {
      ArtistDetailView(
        artist: .previewSpoketIKoket,
        topSongs: .previewSpoketIKoketTopSongs,
        releases: .previewSpoketIKoketReleases,
      )
    }
  }

  #Preview("Artist detail playing") {
    NavigationStack {
      ArtistDetailView(
        artist: .previewSpoketIKoket,
        topSongs: .previewSpoketIKoketTopSongs,
        releases: .previewSpoketIKoketReleases,
        currentTrackID: [ArtistTopSongData].previewSpoketIKoketTopSongs[0].id,
        isPlaying: true,
      )
    }
  }

  #Preview("Artist detail empty") {
    NavigationStack {
      ArtistDetailView(artist: .previewSpoketIKoket)
    }
  }

  #Preview("Artist detail narrow") {
    NavigationStack {
      ArtistDetailView(
        artist: .previewSpoketIKoket,
        topSongs: .previewSpoketIKoketTopSongs,
        releases: .previewSpoketIKoketReleases,
      )
    }
    .frame(width: 320, height: 568)
  }

  #Preview("Artist detail wide") {
    NavigationStack {
      ArtistDetailView(
        artist: .previewSpoketIKoket,
        topSongs: .previewSpoketIKoketTopSongs,
        releases: .previewSpoketIKoketReleases,
      )
    }
    .frame(width: 1024, height: 768)
  }

  #Preview("Artist detail accessibility text") {
    NavigationStack {
      ArtistDetailView(
        artist: .previewSpoketIKoket,
        topSongs: .previewSpoketIKoketTopSongs,
        releases: .previewSpoketIKoketReleases,
      )
    }
    .environment(\.dynamicTypeSize, .accessibility3)
    .frame(width: 600, height: 700)
  }
#endif
