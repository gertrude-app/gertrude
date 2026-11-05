import ComposableArchitecture
import Foundation
import LibViews
import SwiftUI

#if os(iOS)
  import UIKit
#endif

struct LibraryViewContainer: View {
  @Bindable var store: StoreOf<LibraryFeature>
  @Bindable var searchStore: StoreOf<SearchFeature>
  @Namespace private var zoomNamespace
  @State private var sidebarPresentation = LibrarySidebarPresentation()
  @State private var compactColumnChoice: NavigationSplitViewColumn?
  #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  let currentTrackID: ApprovedTrack.ID?
  let activePlaybackContext: PlaybackContext?
  let isPlaybackLoading: Bool
  let isPlaybackPlaying: Bool

  var body: some View {
    self.navigationContent
      .onGeometryChange(for: LibrarySplitViewGeometry.self) { proxy in
        self.splitViewGeometry(in: proxy)
      } action: { geometry in
        self.sidebarPresentation.updateGeometry(geometry)
      }
      .onChange(of: self.store.selectedCollectionIdentity == nil, initial: true) { _, isEmpty in
        self.sidebarPresentation.selectionChanged(hasSelection: !isEmpty)
      }
      .onChange(of: self.store.selectedCollectionIdentity) {
        self.compactColumnChoice = nil
      }
  }

  private var navigationContent: some View {
    NavigationSplitView(
      columnVisibility: self.columnVisibility,
      preferredCompactColumn: self.compactColumn,
    ) {
      self.sidebarContent
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { frame in
          self.sidebarPresentation.sidebarFrame = frame
        }
        .navigationSplitViewColumnWidth(min: 360, ideal: 420, max: 600)
    } detail: {
      self.content(.detail)
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { frame in
          self.sidebarPresentation.detailFrame = frame
        }
        .onDisappear {
          guard self.isCompact,
                self.compactColumnChoice == .sidebar,
                self.store.selectedCollectionIdentity != nil else { return }
          self.store.send(.selectionChanged(nil))
        }
    }
    .navigationSplitViewStyle(.balanced)
    #if os(iOS)
      .ignoresSafeArea(.container, edges: .top)
      .background(alignment: .leading) {
        if !self.usesNativeSidebarBackground,
           let width = self.sidebarPresentation.backgroundWidth {
          Color(.secondarySystemBackground)
            .frame(width: width)
            .ignoresSafeArea(.container, edges: .top)
            .allowsHitTesting(false)
        }
      }
    #endif
  }

  private var sidebarContent: some View {
    #if os(iOS)
      Group {
        if #available(iOS 18.0, *) {
          self.content(self.sidebarLayout)
            .containerBackground(self.sidebarBackground, for: .navigation)
        } else if self.isCompact {
          self.content(self.sidebarLayout)
        } else {
          self.content(self.sidebarLayout)
            .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
        }
      }
      .scrollContentBackground(self.isCompact ? .automatic : .hidden)
      .backgroundStyle(self.sidebarBackground)
      .background(self.sidebarBackground)
    #else
      self.content(.sidebar)
    #endif
  }

  #if os(iOS)
    private var sidebarBackground: Color {
      self.isCompact ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }
  #endif

  private var sidebarLayout: LibraryContentViewContainer.Layout {
    self.isCompact ? .compact : .sidebar
  }

  private var compactColumn: Binding<NavigationSplitViewColumn> {
    Binding(
      get: {
        self.compactColumnChoice
          ?? (self.store.selectedCollectionIdentity == nil ? .sidebar : .detail)
      },
      set: { self.compactColumnChoice = $0 },
    )
  }

  private func content(_ layout: LibraryContentViewContainer
    .Layout) -> LibraryContentViewContainer {
    LibraryContentViewContainer(
      store: self.store,
      searchStore: self.searchStore,
      layout: layout,
      currentTrackID: self.currentTrackID,
      activePlaybackContext: self.activePlaybackContext,
      isPlaybackLoading: self.isPlaybackLoading,
      isPlaybackPlaying: self.isPlaybackPlaying,
      transitionNamespace: self.isCompact ? self.zoomNamespace : nil,
      onCollectionSelected: {
        self.compactColumnChoice = .detail
        withAnimation {
          self.sidebarPresentation.selectCollection(isCompact: self.isCompact)
        }
      },
    )
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

  private var isCompact: Bool {
    #if os(iOS)
      self.horizontalSizeClass == .compact
    #else
      false
    #endif
  }

  private var usesNativeSidebarBackground: Bool {
    #if os(iOS)
      UIDevice.current.userInterfaceIdiom == .pad
    #else
      false
    #endif
  }

  private var columnVisibility: Binding<NavigationSplitViewVisibility> {
    Binding(
      get: { self.sidebarPresentation.visibility },
      set: { self.sidebarPresentation.updateVisibility($0) },
    )
  }
}

struct LibraryContentViewContainer: View {
  enum Layout {
    case compact
    case sidebar
    case detail
  }

  @Bindable var store: StoreOf<LibraryFeature>
  @Bindable var searchStore: StoreOf<SearchFeature>
  @State private var isSearchPresented = false

  let layout: Layout
  let currentTrackID: ApprovedTrack.ID?
  let activePlaybackContext: PlaybackContext?
  let isPlaybackLoading: Bool
  let isPlaybackPlaying: Bool
  let transitionNamespace: Namespace.ID?
  let onCollectionSelected: @MainActor @Sendable () -> Void

  var body: some View {
    switch self.layout {
    case .compact, .sidebar:
      self.searchableLibraryContent
    case .detail:
      self.detailContent
    }
  }

  private var searchableLibraryContent: some View {
    self.libraryContent
      .searchable(
        text: self.$searchStore.query.sending(\.queryChanged),
        isPresented: self.$isSearchPresented,
        prompt: "Search your music",
      )
  }

  private var libraryContent: some View {
    LibraryView(
      state: self.store.viewState,
      searchQuery: self.searchStore.query,
      searchResults: self.searchStore.results.map(\.viewData),
      currentTrackID: self.currentTrackID?.rawValue,
      isPlaybackPlaying: self.isPlaybackPlaying,
      playingItemID: self.playingItemID,
      selectedItemID: self.selectedItemID,
      isRefreshing: self.store.isRefreshingRemoteLibrary,
      isPlaylistMutationInFlight: self.store.isPlaylistMutationInFlight,
      transitionNamespace: self.transitionNamespace,
      onSearchTap: { self.isSearchPresented = true },
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
      searchActions: .init(
        onTap: self.searchResultTapped,
        onPlayNext: { self.sendSearchResultAction(
          $0,
          action: SearchFeature.Action.resultPlayNextTapped,
        ) },
        onAddToQueue: { self.sendSearchResultAction(
          $0,
          action: SearchFeature.Action.resultAddToQueueTapped,
        ) },
        onAddToPlaylist: { self.sendSearchResultAction(
          $0,
          action: SearchFeature.Action.resultAddToPlaylistTapped,
        ) },
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
    self.onCollectionSelected()
  }

  private func searchResultTapped(_ rawID: String) {
    guard let resultID = MusicSearchResult.ID(rawValue: rawID),
          self.searchStore.results.contains(where: { $0.id == resultID }) else { return }
    self.searchStore.send(.resultTapped(resultID))
    switch resultID {
    case .album, .artist, .playlist:
      self.onCollectionSelected()
    case .song:
      break
    }
  }

  private func sendSearchResultAction(
    _ rawID: String,
    action: (MusicSearchResult.ID) -> SearchFeature.Action,
  ) {
    guard let resultID = MusicSearchResult.ID(rawValue: rawID) else { return }
    self.searchStore.send(action(resultID))
  }

  private var detailContent: some View {
    NavigationStack(path: self.detailPathIDs) {
      Group {
        if let id = self.store.path.ids.first {
          self.destination(id: id)
            .id(id)
        } else {
          LibraryNoSelectionView()
        }
      }
      .navigationDestination(for: StackElementID.self) { id in
        self.destination(id: id)
      }
    }
  }

  private var detailPathIDs: Binding<[StackElementID]> {
    Binding(
      get: { Array(self.store.detailPath.ids) },
      set: { ids in
        let current = self.store.detailPath.ids
        guard ids.count < current.count else { return }
        self.store.send(.path(.popFrom(id: current[ids.count])))
      },
    )
  }

  @ViewBuilder
  private func destination(id: StackElementID) -> some View {
    if let pathStore = self.store.scope(\.path[id: id], action: \.path[id: id]) {
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

  private var selectedItemID: String? {
    guard self.layout != .compact,
          let selection = self.store.selectedCollectionIdentity else { return nil }
    return "\(selection.kind.rawValue)-\(selection.id)"
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
  private(set) var showsLibraryForMissingSelection = false

  var backgroundWidth: CGFloat? {
    guard self.visibility != .detailOnly,
          let sidebarFrame, let detailFrame, let geometry,
          !sidebarFrame.isEmpty, !sidebarFrame.isInfinite,
          !detailFrame.isEmpty, !detailFrame.isInfinite,
          detailFrame.width < geometry.size.width - 1,
          sidebarFrame.maxX <= detailFrame.minX + 1
          || detailFrame.maxX <= sidebarFrame.minX + 1 else { return nil }
    return sidebarFrame.width
  }

  mutating func selectCollection(isCompact: Bool) {
    guard !isCompact, let sidebarFrame, let detailFrame else { return }
    let overlap = sidebarFrame.intersection(detailFrame)
    guard !overlap.isNull, overlap.width > 1, overlap.height > 1 else { return }
    self.visibility = .detailOnly
    self.didDismissOverlay = true
  }

  mutating func selectionChanged(hasSelection: Bool) {
    if hasSelection {
      guard self.showsLibraryForMissingSelection else { return }
      self.showsLibraryForMissingSelection = false
      if self.visibility == .all {
        self.visibility = .automatic
      }
    } else {
      self.visibility = .all
      self.didDismissOverlay = false
      self.showsLibraryForMissingSelection = true
    }
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
