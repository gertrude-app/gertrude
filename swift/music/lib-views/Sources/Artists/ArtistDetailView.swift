import SwiftUI

public struct ArtistDetailView: View {
  private let artist: ArtistDetailData
  private let topSongs: [ArtistTopSongData]
  private let releases: [ArtistReleaseData]
  private let transitionNamespace: Namespace.ID?
  private let currentTrackID: String?
  private let isPlaying: Bool
  private let isLoading: Bool
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onPlayTap: @MainActor @Sendable () -> Void
  private let onSongAddToQueue: @MainActor @Sendable (String) -> Void
  private let onSongPlayNext: @MainActor @Sendable (String) -> Void
  private let onSongTap: @MainActor @Sendable (String) -> Void
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
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
    onSongAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onSongPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onSongTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
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
    self.onAddToQueue = onAddToQueue
    self.onPlayNext = onPlayNext
    self.onPlayTap = onPlayTap
    self.onSongAddToQueue = onSongAddToQueue
    self.onSongPlayNext = onSongPlayNext
    self.onSongTap = onSongTap
    self.onReleaseAddToQueue = onReleaseAddToQueue
    self.onReleasePlayNext = onReleasePlayNext
    self.onReleaseTap = onReleaseTap
  }

  public var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 30) {
          ArtistDetailHeroView(
            artist: self.artist,
            isPlaying: self.isPlaying,
            isLoading: self.isLoading,
            onPlayTap: self.onPlayTap,
          )
          .playbackQueueContextMenu(
            onPlayNext: self.onPlayNext,
            onAddToQueue: self.onAddToQueue,
          )
          .padding(.horizontal, 20)
          .padding(.top, proxy.frame(in: .global).minY + 18)
          .padding(.bottom, 24)
          .background {
            if let backgroundColor = self.artist.artworkPalette?.backgroundColor {
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

          ArtistTopSongsShelf(
            songs: self.topSongs,
            currentTrackID: self.currentTrackID,
            isPlaying: self.isPlaying,
            onSongAddToQueue: self.onSongAddToQueue,
            onSongPlayNext: self.onSongPlayNext,
            onSongTap: self.onSongTap,
          )

          ArtistReleasesShelf(
            releases: self.releases,
            transitionNamespace: self.transitionNamespace,
            onReleaseAddToQueue: self.onReleaseAddToQueue,
            onReleasePlayNext: self.onReleasePlayNext,
            onReleaseTap: self.onReleaseTap,
          )

          if let editorialNotes = self.artist.editorialNotes?.nonEmpty {
            ArtistEditorialNotesSection(notes: editorialNotes)
              .padding(.horizontal, 20)
          }
        }
        .padding(.bottom, 96)
      }
      .background(.background)
      .ignoresSafeArea(edges: .top)
    }
    .navigationTitle("")
    .detailNavigationBarBackground()
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
#endif
