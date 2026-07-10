import ComposableArchitecture
import GertieApp

@Reducer
struct LibraryFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var status = Status.loading
    var isRefreshingRemoteLibrary = false
    var hasStartedInitialLibraryLoad = false
    var pendingAlbumDetail: AlbumDetailFeature.State?
    @Presents var albumDetail: AlbumDetailFeature.State?
  }

  enum Status: Equatable {
    case loading
    case loaded(ApprovedMusicLibrary)
    case empty
    case failed
    case subscriptionRequired
  }

  enum CancelID: Hashable, Sendable {
    case approvedLibraryRefresh
  }

  enum DelegateAction: Equatable {
    case artistPlaybackButtonTapped(items: [PlaybackItem])
    case dismissPlaybackFailure
    case playbackFailureActionTapped
    case playQueue(items: [PlaybackItem], startIndex: Int)
    case togglePlayPause
  }

  enum Action: Equatable {
    case albumTapped(ApprovedAlbum.ID)
    case albumDetail(PresentationAction<AlbumDetailFeature.Action>)
    case albumDetailDismissed(String)
    case approvedLibraryLoaded(ApprovedMusicLibrary)
    case approvedLibraryLoadFailed
    case approvedLibrarySubscriptionRequired
    case artistPlayTapped(ApprovedArtist.ID)
    case artistTopSongTapped(artistID: ApprovedArtist.ID, trackID: ApprovedTrack.ID)
    case cachedApprovedLibraryLoaded(ApprovedMusicLibrary)
    case debugResetOnboardingButtonTapped
    case delegate(DelegateAction)
    case onAppear
    case refreshPresentationFinished
    case refreshPulled
    case retryButtonTapped
  }

  @Dependency(\.approvedMusic) var approvedMusic
  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .albumTapped(let albumID):
        state.presentAlbumDetail(
          albumID: albumID,
          transitionSourceID: albumID.rawValue,
          replacingCurrent: false,
        )
        return .none

      case .albumDetailDismissed(let pushID):
        guard state.albumDetail?.pushID == pushID else { return .none }
        if let pendingAlbumDetail = state.pendingAlbumDetail {
          state.albumDetail = pendingAlbumDetail
          state.pendingAlbumDetail = nil
        } else {
          state.albumDetail = nil
        }
        return .none

      case .artistPlayTapped(let artistID):
        guard let items = self.artistPlaybackItems(
          for: artistID,
          in: state.status,
        ) else { return .none }
        return .send(.delegate(.artistPlaybackButtonTapped(items: items)))

      case .artistTopSongTapped(let artistID, let trackID):
        guard let items = self.artistPlaybackItems(
          for: artistID,
          in: state.status,
        ), let startIndex = items.firstIndex(where: { $0.id == trackID })
        else { return .none }
        return .send(.delegate(.playQueue(items: items, startIndex: startIndex)))

      case .onAppear:
        guard !state.hasStartedInitialLibraryLoad else { return .none }
        state.hasStartedInitialLibraryLoad = true
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: true)

      case .approvedLibraryLoaded(let library):
        state.status = library.isEmpty ? .empty : .loaded(library)
        if library.isEmpty {
          log(.debug, .library, "e24738fc")
        }
        return .none

      case .approvedLibraryLoadFailed:
        log(.err, .library, "cd55459e")
        guard !state.status.isDisplayingLibrary else { return .none }
        state.status = .failed
        return .none

      case .approvedLibrarySubscriptionRequired:
        state.status = .subscriptionRequired
        log(.warn, .subs, "ded74480")
        return .none

      case .cachedApprovedLibraryLoaded(let library):
        state.status = library.isEmpty ? .empty : .loaded(library)
        return .none

      case .refreshPresentationFinished:
        state.isRefreshingRemoteLibrary = false
        return .none

      case .refreshPulled:
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: false)

      case .retryButtonTapped:
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: true)

      case .albumDetail(.presented(.delegate(let delegateAction))):
        switch delegateAction {
        case .dismissPlaybackFailure:
          return .send(.delegate(.dismissPlaybackFailure))
        case .playbackFailureActionTapped:
          return .send(.delegate(.playbackFailureActionTapped))
        case .playAlbum(let items, let startIndex):
          return .send(.delegate(.playQueue(items: items, startIndex: startIndex)))
        case .togglePlayPause:
          return .send(.delegate(.togglePlayPause))
        }

      case .debugResetOnboardingButtonTapped, .delegate, .albumDetail:
        return .none
      }
    }
    .ifLet(\.$albumDetail, action: \.albumDetail) {
      AlbumDetailFeature()
    }
  }

  private func artistPlaybackItems(
    for artistID: ApprovedArtist.ID,
    in status: Status,
  ) -> [PlaybackItem]? {
    guard case .loaded(let library) = status,
          let topSongs = library.artist(id: artistID)?.topSongs,
          !topSongs.isEmpty else { return nil }
    return topSongs.map {
      PlaybackItem(track: $0, artworkURL: $0.artworkURL)
    }
  }

  private func refreshRemoteApprovedLibrary(loadCache: Bool) -> EffectOf<Self> {
    .run { send in
      async let minimumDisplayDuration: Void = self.clock.sleep(for: .milliseconds(1500))
      if loadCache,
         let cachedLibrary = await self.approvedMusic.loadCachedApprovedLibrary() {
        await send(.cachedApprovedLibraryLoaded(cachedLibrary))
      }
      do {
        try await send(.approvedLibraryLoaded(self.approvedMusic.loadRemoteApprovedLibrary()))
      } catch ApprovedMusicClientError.subscriptionRequired {
        await send(.approvedLibrarySubscriptionRequired)
      } catch {
        await send(.approvedLibraryLoadFailed)
      }
      try await minimumDisplayDuration
      await send(.refreshPresentationFinished)
    }
    .cancellable(id: CancelID.approvedLibraryRefresh, cancelInFlight: true)
  }
}

private extension LibraryFeature.Status {
  var isDisplayingLibrary: Bool {
    switch self {
    case .loaded, .empty:
      true
    case .loading, .failed, .subscriptionRequired:
      false
    }
  }
}

extension LibraryFeature.State {
  @discardableResult
  mutating func presentAlbumDetail(
    albumID: ApprovedAlbum.ID,
    transitionSourceID: String?,
    replacingCurrent: Bool,
  ) -> Bool {
    guard case .loaded(let library) = self.status,
          let album = library.album(id: albumID)
    else { return false }

    if self.albumDetail?.album.id == albumID {
      self.pendingAlbumDetail = nil
      return true
    }

    let albumDetail = AlbumDetailFeature.State(
      album: album,
      transitionSourceID: transitionSourceID,
    )

    if replacingCurrent,
       let currentAlbumDetail = self.albumDetail,
       currentAlbumDetail.pushID != albumDetail.pushID {
      self.pendingAlbumDetail = albumDetail
    } else {
      self.pendingAlbumDetail = nil
      self.albumDetail = albumDetail
    }
    return true
  }

  mutating func setAlbumDetailPlaybackFailure(_ failure: PlaybackFailure?) {
    if var pendingAlbumDetail = self.pendingAlbumDetail {
      pendingAlbumDetail.setPlaybackFailure(failure)
      self.pendingAlbumDetail = pendingAlbumDetail
    }
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackFailure(failure)
    self.albumDetail = albumDetail
  }

  mutating func setAlbumDetailPlaybackSession(_ session: PlaybackFeature.Session?) {
    if var pendingAlbumDetail = self.pendingAlbumDetail {
      pendingAlbumDetail.setPlaybackSession(session)
      self.pendingAlbumDetail = pendingAlbumDetail
    }
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackSession(session)
    self.albumDetail = albumDetail
  }
}
