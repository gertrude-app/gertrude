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

  enum Action: Equatable {
    case onAppear
    case approvedLibraryLoaded(ApprovedMusicLibrary)
    case approvedLibraryLoadFailed
    case approvedLibrarySubscriptionRequired
    case cachedApprovedLibraryLoaded(ApprovedMusicLibrary)
    case refreshPresentationFinished
    case refreshPulled
    case retryButtonTapped
    case albumTapped(ApprovedAlbum.ID)
    case albumDetailDismissed(String)
    case debugResetOnboardingButtonTapped
    case delegate(AlbumDetailFeature.Action.DelegateAction)
    case albumDetail(PresentationAction<AlbumDetailFeature.Action>)
  }

  @Dependency(\.approvedMusic) var approvedMusic
  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard !state.hasStartedInitialLibraryLoad else { return .none }
        state.hasStartedInitialLibraryLoad = true
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: true)

      case .approvedLibraryLoaded(let library):
        state.status = library.albums.isEmpty ? .empty : .loaded(library)
        if library.albums.isEmpty {
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
        state.status = library.albums.isEmpty ? .empty : .loaded(library)
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

      case .albumDetail(.presented(.delegate(let delegateAction))):
        return .send(.delegate(delegateAction))

      case .debugResetOnboardingButtonTapped, .delegate, .albumDetail:
        return .none
      }
    }
    .ifLet(\.$albumDetail, action: \.albumDetail) {
      AlbumDetailFeature()
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
