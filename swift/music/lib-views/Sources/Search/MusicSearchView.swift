import SwiftUI

public enum MusicSearchViewState: Equatable, Sendable {
  case emptyLibrary
  case failed
  case loading
  case ready([MusicSearchResultData])
  case musicAccessUnavailable
}

public struct MusicSearchView: View {
  @Binding private var query: String

  private let state: MusicSearchViewState
  private let currentTrackID: String?
  private let isPlaybackPlaying: Bool
  private let transitionNamespace: Namespace.ID?
  private let onAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onAddToQueue: @MainActor @Sendable (String) -> Void
  private let onPlayNext: @MainActor @Sendable (String) -> Void
  private let onResultTap: @MainActor @Sendable (String) -> Void
  private let onRetryTap: @MainActor @Sendable () -> Void

  public init(
    state: MusicSearchViewState,
    query: Binding<String>,
    currentTrackID: String? = nil,
    isPlaybackPlaying: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onResultTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onRetryTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.state = state
    self._query = query
    self.currentTrackID = currentTrackID
    self.isPlaybackPlaying = isPlaybackPlaying
    self.transitionNamespace = transitionNamespace
    self.onAddToPlaylist = onAddToPlaylist
    self.onAddToQueue = onAddToQueue
    self.onPlayNext = onPlayNext
    self.onResultTap = onResultTap
    self.onRetryTap = onRetryTap
  }

  public var body: some View {
    #if os(iOS)
      self.searchContent
        .navigationBarTitleDisplayMode(.large)
    #else
      self.searchContent
    #endif
  }

  private var searchContent: some View {
    self.content
      .navigationTitle("Search")
      .searchable(
        text: self.$query,
        prompt: "Search your music",
      )
  }

  @ViewBuilder private var content: some View {
    switch self.state {
    case .loading:
      ProgressView("Loading music")
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .ready(let results):
      if self.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        ContentUnavailableView(
          "Search your music",
          systemImage: "magnifyingglass",
          description: Text("Find songs, albums, artists, and playlists."),
        )
      } else if results.isEmpty {
        ContentUnavailableView("No results", systemImage: "magnifyingglass")
      } else {
        List(results) { result in
          MusicSearchResultRow(
            result: result,
            isCurrent: result.kind == .song && result.collectionID == self.currentTrackID,
            isPlaying: self.isPlaybackPlaying,
            transitionNamespace: self.transitionNamespace,
            onAddToPlaylist: { self.onAddToPlaylist(result.id) },
            onAddToQueue: { self.onAddToQueue(result.id) },
            onPlayNext: { self.onPlayNext(result.id) },
            onTap: { self.onResultTap(result.id) },
          )
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.interactively)
      }

    case .emptyLibrary:
      self.messageContent(
        title: "No music yet",
        message: "Approved artists, albums, and your playlists will appear here.",
        systemImage: "rectangle.stack",
        buttonTitle: "Check again",
      )

    case .failed:
      self.messageContent(
        title: "Couldn’t load library",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        buttonTitle: "Try again",
      )

    case .musicAccessUnavailable:
      self.messageContent(
        title: "Music unavailable",
        message: "This device is connected, but Gertrude Music isn’t available for this account.",
        systemImage: "music.note",
        buttonTitle: "Check again",
      )
    }
  }

  private func messageContent(
    title: String,
    message: String,
    systemImage: String,
    buttonTitle: String,
  ) -> some View {
    ScrollView {
      LibraryMessageCard(
        title: title,
        message: message,
        systemImage: systemImage,
        buttonTitle: buttonTitle,
        onButtonTap: self.onRetryTap,
      )
      .frame(maxWidth: 600)
      .padding(.horizontal, 20)
      .padding(.top, 48)
      .padding(.bottom, 96)
    }
    .background(.background)
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
    case .album, .song:
      self.onAddToPlaylist
    case .artist, .playlist:
      nil
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

private struct MusicSearchResultArtwork: View {
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
  #Preview("Search results") {
    @Previewable @State var query = "queen"
    NavigationStack {
      MusicSearchView(
        state: .ready([
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
        ]),
        query: $query,
        currentTrackID: "killer-queen",
        isPlaybackPlaying: true,
      )
    }
  }

  #Preview("Search empty") {
    @Previewable @State var query = ""
    NavigationStack {
      MusicSearchView(
        state: .ready([]),
        query: $query,
      )
    }
  }
#endif
