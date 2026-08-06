import ComposableArchitecture
import GertieApp
import GertieTcaFeatures

@Reducer
struct AppFeature: Sendable {
  enum Tab: Equatable, Hashable, Sendable {
    case library
    case queue
    case search
  }

  @ObservableState
  struct State: Equatable {
    var killSwitch = KillSwitchFeature.State()
    var library = LibraryFeature.State()
    var playback = PlaybackFeature.State()
    var pendingLibraryPlayNowOrigin: LibraryCollectionIdentity?
    var search = SearchFeature.State()
    var setup = MusicSetupFeature.State()
    var isNowPlayingPresented = false
    var selectedTab = Tab.library
  }

  enum Action: Equatable {
    case killSwitch(KillSwitchFeature.Action)
    case library(LibraryFeature.Action)
    case nowPlayingAddToPlaylistTapped
    case nowPlayingAlbumInfoTapped
    case nowPlayingPresentationChanged(Bool)
    case playback(PlaybackFeature.Action)
    case playbackAlbumIDsResolved(ApprovedTrack.ID, [ApprovedAlbum.ID])
    case queueBrowseLibraryButtonTapped
    case search(SearchFeature.Action)
    case setup(MusicSetupFeature.Action)
    case tabSelected(Tab)
  }

  enum CancelID: Hashable {
    case albumResolution
  }

  @Dependency(\.keychain) var keychain
  @Dependency(\.device) var device
  @Dependency(\.playback) var playback
  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    Scope(state: \.killSwitch, action: \.killSwitch) {
      KillSwitchFeature(app: .music) {
        guard let deviceId = await self.device.vendorId() else {
          throw KillSwitchDeviceIdError.missingDeviceId
        }
        return deviceId
      }
    }

    Scope(state: \.library, action: \.library) {
      LibraryFeature()
    }

    Scope(state: \.playback, action: \.playback) {
      PlaybackFeature()
    }

    Scope(state: \.search, action: \.search) {
      SearchFeature()
    }

    Scope(state: \.setup, action: \.setup) {
      MusicSetupFeature()
    }

    Reduce { state, action in
      switch action {
      case .nowPlayingAddToPlaylistTapped:
        guard let currentItem = state.playback.session?.currentItem,
              let albumID = currentItem.albumID else { return .none }
        return .send(.library(.addTrackToPlaylistTapped(
          trackID: currentItem.id,
          albumID: albumID,
        )))

      case .nowPlayingAlbumInfoTapped:
        guard let albumID = state.playback.session?.currentItem.albumID else { return .none }
        guard state.library.pushAlbumDetail(albumID: albumID) else { return .none }
        state.isNowPlayingPresented = false
        state.selectedTab = .library
        self.synchronizeDetailPlayback(state: &state)
        return .none

      case .killSwitch:
        return .none

      case .nowPlayingPresentationChanged(let isPresented):
        state.isNowPlayingPresented = isPresented
        return .none

      case .queueBrowseLibraryButtonTapped:
        state.selectedTab = .library
        return .none

      case .tabSelected(let tab):
        state.selectedTab = tab
        if tab == .search {
          state.search.applyLibraryStatus(state.library.status)
        }
        return .none

      #if DEBUG
        case .library(.debugResetOnboardingButtonTapped):
          self.keychain.deleteConnection()
          self.keychain.save(deviceId: self.uuid())
          state.isNowPlayingPresented = false
          state.library = .init()
          state.playback = .init()
          state.pendingLibraryPlayNowOrigin = nil
          state.search = .init()
          state.setup = .init()
          state.selectedTab = .library
          return .merge(
            .cancel(id: MusicSetupFeature.CancelID.musicAppStatusPolling),
            .cancel(id: PlaybackFeature.CancelID.playbackEvents),
            .run { _ in await self.playback.stop() },
          )
      #endif

      case .library(.delegate(.addToQueue(let items))):
        state.pendingLibraryPlayNowOrigin = nil
        return .send(.playback(.addToQueue(items)))

      case .library(.delegate(.approvedTrackIDsUpdated(let approvedTrackIDs))):
        return .send(.playback(.approvedTrackIDsUpdated(approvedTrackIDs)))

      case .library(.delegate(.artistPlaybackButtonTapped(let items, let context))):
        guard !items.isEmpty else { return .none }
        if state.playback.activePlaybackContext?.identity == context.identity {
          state.pendingLibraryPlayNowOrigin = nil
          return .send(.playback(.togglePlayPause))
        }
        state.pendingLibraryPlayNowOrigin = context.identity
        return .send(.playback(.playNow(
          items: items,
          startIndex: 0,
          context: context,
        )))

      case .library(.delegate(.dismissPlaybackFailure)):
        return .send(.playback(.playbackFailureDismissed))

      case .library(.delegate(.playbackFailureActionTapped)):
        return .send(.playback(.playbackFailureActionTapped))

      case .library(.delegate(.playNext(let items))):
        state.pendingLibraryPlayNowOrigin = nil
        return .send(.playback(.playNext(items)))

      case .library(.delegate(.playNow(let items, let startIndex, let context))):
        state.pendingLibraryPlayNowOrigin = context.identity
        return .send(.playback(.playNow(
          items: items,
          startIndex: startIndex,
          context: context,
        )))

      case .library(.delegate(.togglePlayPause)):
        return .send(.playback(.togglePlayPause))

      case .library:
        state.search.applyLibraryStatus(state.library.status)
        self.synchronizeDetailPlayback(state: &state)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playback(.playNowFinished):
        let origin = state.pendingLibraryPlayNowOrigin
        state.pendingLibraryPlayNowOrigin = nil
        self.synchronizeDetailPlayback(state: &state)
        let resolveAlbum = self.resolveCurrentPlaybackAlbum(state: &state)
        guard state.playback.hasAuthoritativeSnapshot, let origin else {
          return resolveAlbum
        }
        return .merge(
          resolveAlbum,
          .send(.library(.collectionPlayNowSucceeded(origin))),
        )

      case .playback(.playbackFailed):
        state.pendingLibraryPlayNowOrigin = nil
        self.synchronizeDetailPlayback(state: &state)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playback(.playbackEvent(.queueEnded)):
        state.pendingLibraryPlayNowOrigin = nil
        state.isNowPlayingPresented = false
        self.synchronizeDetailPlayback(state: &state)
        return .cancel(id: CancelID.albumResolution)

      case .playback(.playbackEvent(.progressChanged)):
        return .none

      case .playback(let playbackAction):
        switch playbackAction {
        case .addToQueue,
             .clearQueueButtonTapped,
             .playNext,
             .queueEntryRemoveRequested,
             .reorderUpcoming,
             .stop:
          state.pendingLibraryPlayNowOrigin = nil
        default:
          break
        }
        self.synchronizeDetailPlayback(state: &state)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playbackAlbumIDsResolved(let songID, let albumIDs):
        guard state.playback.session?.currentTrackID == songID,
              case .loaded(let library) = state.library.status else { return .none }
        let approvedAlbumIDs = Set(library.albums.map(\.id))
        guard let albumID = albumIDs
          .filter({ approvedAlbumIDs.contains($0) })
          .sorted(by: { $0.rawValue < $1.rawValue })
          .first else { return .none }
        state.playback.setSourceAlbumID(albumID, for: songID)
        self.synchronizeDetailPlayback(state: &state)
        return .send(.playback(.saveCachedSession))

      case .search(.delegate(.browseLibrary)):
        state.selectedTab = .library
        return .none

      case .search(.delegate(.library(let action))):
        return .send(.library(action))

      case .search(.delegate(.playback(let action))):
        return .send(.library(.delegate(action)))

      case .search(.delegate(.songTapped(let item))):
        state.pendingLibraryPlayNowOrigin = nil
        if state.playback.session?.currentTrackID == item.id {
          return .send(.playback(.togglePlayPause))
        }
        return .send(.playback(.playNow(
          items: [item],
          startIndex: 0,
          context: nil,
        )))

      case .search:
        self.synchronizeDetailPlayback(state: &state)
        return .none

      case .setup:
        return .none
      }
    }
  }

  private func synchronizeDetailPlayback(state: inout State) {
    state.library.setAlbumDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.library.setPlaylistDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
    state.library.setPlaylistDetailPlaybackFailure(state.playback.failure)
    state.search.setAlbumDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.search.setPlaylistDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.search.setAlbumDetailPlaybackFailure(state.playback.failure)
    state.search.setPlaylistDetailPlaybackFailure(state.playback.failure)
  }

  private func resolveCurrentPlaybackAlbum(
    state: inout State,
  ) -> EffectOf<Self> {
    guard state.playback.hasAuthoritativeSnapshot,
          case .loaded(let library) = state.library.status,
          let currentItem = state.playback.session?.currentItem else { return .none }
    let previousAlbumID = currentItem.albumID
    _ = state.playback.resolveCurrentAlbum(in: library)
    if state.playback.session?.currentItem.albumID != previousAlbumID {
      self.synchronizeDetailPlayback(state: &state)
      return .send(.playback(.saveCachedSession))
    }
    guard state.playback.session?.currentItem.albumID == nil,
          state.playback.pendingAlbumResolutionSongID != currentItem.id else { return .none }
    state.playback.pendingAlbumResolutionSongID = currentItem.id
    return .run { send in
      let albumIDs = await (try? self.playback.loadAlbumIDs(currentItem.id)) ?? []
      try Task.checkCancellation()
      await send(.playbackAlbumIDsResolved(currentItem.id, albumIDs))
    }
    .cancellable(id: CancelID.albumResolution, cancelInFlight: true)
  }
}
