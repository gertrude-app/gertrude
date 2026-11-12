import GertieUI
import SwiftUI

struct MusicSearchResultsView: View {
  let results: [MusicSearchResultData]
  let currentTrackID: String?
  let isPlaybackPlaying: Bool
  let selectedItemID: String?
  let transitionNamespace: Namespace.ID?
  let actions: LibraryItemActions

  var body: some View {
    if self.results.isEmpty {
      MusicEmptyState("No results")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      List(self.results) { result in
        MusicSearchResultRow(
          result: result,
          isCurrent: result.kind == .song && result.collectionID == self.currentTrackID,
          isPlaying: self.isPlaybackPlaying,
          transitionNamespace: self.transitionNamespace,
          onAddToPlaylist: { self.actions.onAddToPlaylist(result.id) },
          onAddToQueue: { self.actions.onAddToQueue(result.id) },
          onPlayNext: { self.actions.onPlayNext(result.id) },
          onTap: { self.actions.onTap(result.id) },
        )
        .listRowBackground(
          result.id == self.selectedItemID ? Color.primary.opacity(0.1) : .clear,
        )
        .accessibilityAddTraits(result.id == self.selectedItemID ? .isSelected : [])
      }
      .listStyle(.plain)
      .scrollDismissesKeyboard(.interactively)
    }
  }
}

private struct MusicSearchResultRow: View {
  let result: MusicSearchResultData
  let isCurrent: Bool
  let isPlaying: Bool
  let transitionNamespace: Namespace.ID?
  let onAddToPlaylist: @MainActor @Sendable () -> Void
  let onAddToQueue: @MainActor @Sendable () -> Void
  let onPlayNext: @MainActor @Sendable () -> Void
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 12) {
        MusicSearchResultArtwork(
          result: self.result,
          transitionNamespace: self.transitionNamespace,
        )

        VStack(alignment: .leading, spacing: 3) {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            if self.isCurrent {
              PlaybackWaveformView(
                isPlaying: self.isPlaying,
                color: .gertrudeBrandAccent,
                barCount: 3,
                barWidth: 2.25,
                barSpacing: 1.5,
                minimumBarHeight: 3,
                maximumBarHeight: 12,
                containerWidth: 10,
                containerHeight: 12,
                alignment: .bottom,
                phaseStep: 1.15,
                minimumInterval: 1.0 / 15.0,
              )
            }

            Text(self.result.title)
              .font(.body.weight(.semibold))
              .foregroundStyle(self.isCurrent ? Color.gertrudeBrandAccent : .primary)
              .lineLimit(2)
          }

          Text(self.result.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .playbackQueueContextMenu(
      onPlayNext: self.onPlayNext,
      onAddToQueue: self.onAddToQueue,
      onAddToPlaylist: self.addToPlaylistAction,
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(self.accessibilityLabel)
  }

  private var addToPlaylistAction: (@MainActor @Sendable () -> Void)? {
    switch self.result.kind {
    case .album, .artist, .playlist, .song:
      self.onAddToPlaylist
    }
  }

  private var accessibilityLabel: String {
    [
      self.isCurrent ? self.isPlaying ? "Playing" : "Paused" : nil,
      self.result.kind.title,
      self.result.title,
      self.result.detail,
    ]
    .compactMap(\.self)
    .joined(separator: ", ")
  }
}

struct MusicSearchResultArtwork: View {
  let result: MusicSearchResultData
  let transitionNamespace: Namespace.ID?

  var body: some View {
    switch self.result.kind {
    case .album:
      MusicSearchSquareArtwork(
        url: self.result.artworkURL,
        systemImage: "square.stack",
      )
      .matchedTransitionSourceIfAvailable(
        id: albumArtworkZoomTransitionID(for: self.result.collectionID),
        in: self.transitionNamespace,
        cornerRadius: 8,
      )

    case .artist:
      MusicSearchArtistArtwork(url: self.result.artworkURL)
        .matchedTransitionSourceIfAvailable(
          id: artistArtworkZoomTransitionID(for: self.result.collectionID),
          in: self.transitionNamespace,
        )

    case .playlist:
      PlaylistArtworkView(
        artworkUrls: self.result.playlistArtworkURLs,
        size: 44,
        cornerRadius: 8,
      )
      .matchedTransitionSourceIfAvailable(
        id: playlistArtworkZoomTransitionID(for: self.result.collectionID),
        in: self.transitionNamespace,
        cornerRadius: 8,
      )

    case .song:
      MusicSearchSquareArtwork(
        url: self.result.artworkURL,
        systemImage: "music.note",
      )
    }
  }
}

private struct MusicSearchSquareArtwork: View {
  let url: URL?
  let systemImage: String

  var body: some View {
    CachedArtworkImageView(url: self.url) { image in
      image
        .resizable()
        .scaledToFill()
        .frame(width: 44, height: 44)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
    } placeholder: {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.gertrudeBrandAccent.opacity(0.14))
        .frame(width: 44, height: 44)
        .overlay {
          Image(systemName: self.systemImage)
            .foregroundStyle(Color.gertrudeBrandAccent)
        }
    }
    .accessibilityHidden(true)
  }
}

private struct MusicSearchArtistArtwork: View {
  let url: URL?

  var body: some View {
    CachedArtworkImageView(url: self.url) { image in
      image
        .resizable()
        .scaledToFill()
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    } placeholder: {
      Circle()
        .fill(Color.gertrudeBrandAccent.opacity(0.14))
        .frame(width: 44, height: 44)
        .overlay {
          Image(systemName: "person.fill")
            .foregroundStyle(Color.gertrudeBrandAccent)
        }
    }
    .accessibilityHidden(true)
  }
}

#if DEBUG
  #Preview("Library search results") {
    @Previewable @State var query = "queen"
    @Previewable @State var isSearchPresented = true
    NavigationSplitView {
      LibraryView(
        state: .loaded(items: [AlbumData].previewAlbums.map(LibraryCollectionItemData.album)),
        searchQuery: query,
        searchResults: [
          .init(
            id: "artist-queen",
            kind: .artist,
            collectionID: "queen",
            title: "Queen",
          ),
          .init(
            id: "song-killer-queen",
            kind: .song,
            collectionID: "killer-queen",
            title: "Killer Queen",
            detail: "Queen · Sheer Heart Attack",
          ),
          .init(
            id: "album-queen-ii",
            kind: .album,
            collectionID: "queen-ii",
            title: "Queen II",
            detail: "Queen",
          ),
        ],
        currentTrackID: "killer-queen",
        isPlaybackPlaying: true,
        selectedItemID: "album-queen-ii",
      )
      .searchable(
        text: $query,
        isPresented: $isSearchPresented,
        prompt: "Search your music",
      )
    } detail: {
      LibraryNoSelectionView()
    }
    .navigationSplitViewStyle(.balanced)
  }

  #Preview("Search empty") {
    NavigationStack {
      MusicSearchResultsView(
        results: [],
        currentTrackID: nil,
        isPlaybackPlaying: false,
        selectedItemID: nil,
        transitionNamespace: nil,
        actions: .init(),
      )
      .navigationTitle("Library")
    }
  }
#endif
