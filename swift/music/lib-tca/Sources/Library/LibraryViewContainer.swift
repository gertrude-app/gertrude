import ComposableArchitecture
import Foundation
import LibViews
import SwiftUI

struct LibraryViewContainer: View {
  @Bindable var store: StoreOf<LibraryFeature>
  @Namespace private var zoomNamespace
  @State private var sidebarPresentation = LibrarySidebarPresentation()
  #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  let currentTrackID: ApprovedTrack.ID?
  let activePlaybackContext: PlaybackContext?
  let isPlaybackLoading: Bool
  let isPlaybackPlaying: Bool

  var body: some View {
    NavigationSplitView(
      columnVisibility: self.columnVisibility,
      preferredCompactColumn: self.preferredCompactColumn,
    ) {
      self.libraryContent
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { frame in
          self.sidebarPresentation.sidebarFrame = frame
        }
        .navigationSplitViewColumnWidth(min: 360, ideal: 420, max: 600)
    } detail: {
      self.detailContent
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { frame in
          self.sidebarPresentation.detailFrame = frame
        }
    }
    .navigationSplitViewStyle(.balanced)
    .onGeometryChange(for: LibrarySplitViewGeometry.self) { proxy in
      self.splitViewGeometry(in: proxy)
    } action: { geometry in
      self.sidebarPresentation.updateGeometry(geometry)
    }
  }

  private var libraryContent: some View {
    LibraryView(
      state: self.store.viewState,
      playingItemID: self.playingItemID,
      selectedItemID: self.selectedItemID,
      isRefreshing: self.store.isRefreshingRemoteLibrary,
      isPlaylistMutationInFlight: self.store.isPlaylistMutationInFlight,
      transitionNamespace: self.transitionNamespace,
      onRetryTap: { self.store.send(.retryButtonTapped) },
      onRefresh: {
        self.store.send(.refreshPulled)
      },
      onCreatePlaylist: { self.store.send(.createPlaylistSubmitted($0)) },
      albumActions: .init(
        onTap: { self.selectCollection(.album(.init($0))) },
        onPlayNext: { self.store.send(.albumPlayNextTapped(.init($0))) },
        onAddToQueue: { self.store.send(.albumAddToQueueTapped(.init($0))) },
        onAddToPlaylist: { self.store.send(.addAlbumToPlaylistTapped(.init($0))) },
      ),
      artistActions: .init(
        onTap: { self.selectCollection(.artist(.init($0))) },
        onPlayNext: { self.store.send(.artistPlayNextTapped(.init($0))) },
        onAddToQueue: { self.store.send(.artistAddToQueueTapped(.init($0))) },
        onAddToPlaylist: { self.store.send(.addArtistToPlaylistTapped(.init($0))) },
      ),
      playlistActions: .init(
        onTap: {
          guard let id = UUID(uuidString: $0) else { return }
          self.selectCollection(.playlist(.init(rawValue: id)))
        },
        onPlayNext: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.playlistPlayNextTapped(.init(rawValue: id)))
        },
        onAddToQueue: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.playlistAddToQueueTapped(.init(rawValue: id)))
        },
        onAddToPlaylist: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.addPlaylistToPlaylistTapped(.init(rawValue: id)))
        },
      ),
      onDebugResetTap: { self.store.send(.debugResetOnboardingButtonTapped) },
    )
    .onAppear {
      self.store.send(.onAppear)
    }
  }

  private func selectCollection(_ selection: LibraryCollectionIdentity) {
    self.store.send(.selectionChanged(selection))
    guard self.store.selectedCollectionIdentity == selection else { return }
    withAnimation {
      self.sidebarPresentation.selectCollection(isCompact: self.isCompact)
    }
  }

  private nonisolated func splitViewGeometry(in proxy: GeometryProxy) -> LibrarySplitViewGeometry {
    #if os(iOS) && compiler(>=6.4)
      if #available(iOS 27.1, *) {
        return LibrarySplitViewGeometry(
          size: proxy.size,
          divisions: proxy.reservedRegions(kind: .division).map(\.frame),
        )
      }
    #endif
    return LibrarySplitViewGeometry(size: proxy.size, divisions: [])
  }

  private var detailContent: some View {
    NavigationStack(
      path: self.$store.scope(\.detailPath, action: \.path),
    ) {
      if let id = self.store.path.ids.first,
         let pathStore = self.store.scope(\.path[id: id], action: \.path[id: id]) {
        self.destination(pathStore)
      } else {
        ContentUnavailableView(
          "Choose some music",
          systemImage: "music.note.list",
          description: Text("Select an album, artist, or playlist from your library."),
        )
      }
    } destination: { pathStore in
      self.destination(pathStore)
    }
  }

  @ViewBuilder
  private func destination(_ pathStore: StoreOf<LibraryPath>) -> some View {
    switch pathStore.case {
    case .album(let albumStore):
      AlbumDetailViewContainer(store: albumStore)
        .navigationZoomTransitionIfAvailable(
          sourceID: albumStore.transitionSourceID.map {
            albumArtworkZoomTransitionID(for: $0)
          },
          in: self.transitionNamespace,
        )

    case .artist(let artistStore):
      if case .loaded(let library) = self.store.status {
        ArtistDetailViewContainer(
          store: artistStore,
          library: library,
          currentTrackID: self.currentTrackID,
          activePlaybackContext: self.activePlaybackContext,
          isPlaybackLoading: self.isPlaybackLoading,
          isPlaybackPlaying: self.isPlaybackPlaying,
          transitionNamespace: self.transitionNamespace,
        )
      }

    case .playlist(let playlistStore):
      PlaylistDetailViewContainer(
        store: playlistStore,
        isPlaylistMutationInFlight: self.store.isPlaylistMutationInFlight,
      )
      .navigationZoomTransitionIfAvailable(
        sourceID: playlistArtworkZoomTransitionID(
          for: playlistStore.playlist.id.rawValue.uuidString,
        ),
        in: self.transitionNamespace,
      )
    }
  }

  private var isCompact: Bool {
    #if os(iOS)
      self.horizontalSizeClass == .compact
    #else
      false
    #endif
  }

  private var transitionNamespace: Namespace.ID? {
    self.isCompact ? self.zoomNamespace : nil
  }

  private var selectedItemID: String? {
    guard !self.isCompact,
          let selection = self.store.selectedCollectionIdentity else { return nil }
    return "\(selection.kind.rawValue)-\(selection.id)"
  }

  private var columnVisibility: Binding<NavigationSplitViewVisibility> {
    Binding(
      get: { self.sidebarPresentation.visibility },
      set: { self.sidebarPresentation.updateVisibility($0) },
    )
  }

  private var preferredCompactColumn: Binding<NavigationSplitViewColumn> {
    Binding(
      get: { self.store.path.isEmpty ? .sidebar : .detail },
      set: { column in
        if column == .sidebar, self.isCompact {
          self.store.send(.selectionChanged(nil))
        }
      },
    )
  }

  private var playingItemID: String? {
    guard self.isPlaybackPlaying,
          let identity = self.activePlaybackContext?.identity else { return nil }
    switch identity.kind {
    case .album:
      return "album-\(identity.id)"
    case .playlist:
      return "playlist-\(identity.id)"
    case .artist:
      return nil
    }
  }
}

private extension LibraryFeature.State {
  var viewState: LibraryViewState {
    switch self.status {
    case .loading:
      .loading
    case .loaded(let library):
      .loaded(items: library.collectionItems(recency: self.collectionRecency))
    case .empty:
      .empty
    case .failed:
      .failed
    case .musicAccessUnavailable:
      .musicAccessUnavailable
    }
  }
}

extension ApprovedMusicLibrary {
  func collectionItems(
    recency: LibraryCollectionRecency,
  ) -> [LibraryCollectionItemData] {
    let albums = self.albums.map {
      DatedLibraryItem(
        addedAt: $0.addedAt,
        identity: .album($0.id),
        item: .album(AlbumData(album: $0)),
      )
    }
    let artists = self.artists.map {
      DatedLibraryItem(
        addedAt: $0.addedAt,
        identity: .artist($0.id),
        item: .artist(ArtistData(artist: $0)),
      )
    }
    let playlists = self.playlists.map {
      DatedLibraryItem(
        addedAt: $0.createdAt,
        identity: .playlist($0.id),
        item: .playlist(PlaylistData(playlist: $0)),
      )
    }
    return (albums + artists + playlists)
      .map { datedItem in
        var datedItem = datedItem
        datedItem.lastPlayedAt = recency.lastPlayedAt(
          for: datedItem.identity,
          observedAddedAt: datedItem.addedAt,
        )
        return datedItem
      }
      .sorted {
        switch ($0.lastPlayedAt, $1.lastPlayedAt) {
        case (.some(let lhs), .some(let rhs)) where lhs != rhs:
          return lhs > rhs
        case (.some, .none):
          return true
        case (.none, .some):
          return false
        default:
          if $0.addedAt != $1.addedAt {
            return $0.addedAt > $1.addedAt
          }
          return $0.item.id < $1.item.id
        }
      }
      .map(\.item)
  }
}

struct LibrarySplitViewGeometry: Equatable {
  let size: CGSize
  let divisions: [CGRect]
}

struct LibrarySidebarPresentation {
  var visibility: NavigationSplitViewVisibility = .automatic
  var sidebarFrame: CGRect?
  var detailFrame: CGRect?
  private(set) var geometry: LibrarySplitViewGeometry?
  private(set) var didDismissOverlay = false

  mutating func selectCollection(isCompact: Bool) {
    guard !isCompact, let sidebarFrame, let detailFrame else { return }
    let overlap = sidebarFrame.intersection(detailFrame)
    guard !overlap.isNull, overlap.width > 1, overlap.height > 1 else { return }
    self.visibility = .detailOnly
    self.didDismissOverlay = true
  }

  mutating func updateVisibility(_ visibility: NavigationSplitViewVisibility) {
    guard self.visibility != visibility else { return }
    self.visibility = visibility
    self.didDismissOverlay = false
  }

  mutating func updateGeometry(_ geometry: LibrarySplitViewGeometry) {
    guard self.geometry != geometry else { return }
    self.geometry = geometry
    guard self.didDismissOverlay else { return }
    self.visibility = .automatic
    self.didDismissOverlay = false
  }
}

private struct DatedLibraryItem {
  let addedAt: Date
  let identity: LibraryCollectionIdentity
  let item: LibraryCollectionItemData
  var lastPlayedAt: Date?
}
