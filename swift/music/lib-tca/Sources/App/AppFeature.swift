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
    var setup = MusicSetupFeature.State()
    var isNowPlayingPresented = false
    var selectedTab = Tab.library
  }

  enum Action: Equatable {
    case killSwitch(KillSwitchFeature.Action)
    case library(LibraryFeature.Action)
    case nowPlayingAlbumInfoTapped
    case nowPlayingPresentationChanged(Bool)
    case playback(PlaybackFeature.Action)
    case playbackAlbumIDsResolved(ApprovedTrack.ID, [ApprovedAlbum.ID])
    case queueBrowseLibraryButtonTapped
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

    Scope(state: \.setup, action: \.setup) {
      MusicSetupFeature()
    }

    Reduce { state, action in
      switch action {
      case .nowPlayingAlbumInfoTapped:
        guard let albumID = state.playback.session?.currentItem.albumID else { return .none }
        guard state.library.presentAlbumDetail(
          albumID: albumID,
          transitionSourceID: nil,
        ) else { return .none }
        state.isNowPlayingPresented = false
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setPlaylistDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        state.library.setPlaylistDetailPlaybackFailure(state.playback.failure)
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
        return .none

      #if DEBUG
        case .library(.debugResetOnboardingButtonTapped):
          self.keychain.deleteConnection()
          self.keychain.save(deviceId: self.uuid())
          state.isNowPlayingPresented = false
          state.library = .init()
          state.playback = .init()
          state.pendingLibraryPlayNowOrigin = nil
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

      case .library(.delegate(.artistPlaybackButtonTapped(let items, let origin))):
        guard !items.isEmpty else { return .none }
        if let currentTrackID = state.playback.session?.currentTrackID,
           items.contains(where: { $0.id == currentTrackID }) {
          state.pendingLibraryPlayNowOrigin = nil
          return .send(.playback(.togglePlayPause))
        }
        state.pendingLibraryPlayNowOrigin = origin
        return .send(.playback(.playNow(items: items, startIndex: 0)))

      case .library(.delegate(.dismissPlaybackFailure)):
        return .send(.playback(.playbackFailureDismissed))

      case .library(.delegate(.playbackFailureActionTapped)):
        return .send(.playback(.playbackFailureActionTapped))

      case .library(.delegate(.playNext(let items))):
        state.pendingLibraryPlayNowOrigin = nil
        return .send(.playback(.playNext(items)))

      case .library(.delegate(.playNow(let items, let startIndex, let origin))):
        state.pendingLibraryPlayNowOrigin = origin
        return .send(.playback(.playNow(items: items, startIndex: startIndex)))

      case .library(.delegate(.togglePlayPause)):
        return .send(.playback(.togglePlayPause))

      case .library:
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setPlaylistDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        state.library.setPlaylistDetailPlaybackFailure(state.playback.failure)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playback(.playNowFinished):
        let origin = state.pendingLibraryPlayNowOrigin
        state.pendingLibraryPlayNowOrigin = nil
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setPlaylistDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        state.library.setPlaylistDetailPlaybackFailure(state.playback.failure)
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
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setPlaylistDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        state.library.setPlaylistDetailPlaybackFailure(state.playback.failure)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playback(.playbackEvent(.queueEnded)):
        state.pendingLibraryPlayNowOrigin = nil
        state.isNowPlayingPresented = false
        state.library.setAlbumDetailPlaybackSession(nil)
        state.library.setPlaylistDetailPlaybackSession(nil)
        state.library.setAlbumDetailPlaybackFailure(nil)
        state.library.setPlaylistDetailPlaybackFailure(nil)
        return .cancel(id: CancelID.albumResolution)

      case .playback(let playbackAction):
        switch playbackAction {
        case .addToQueue,
             .clearUpcomingButtonTapped,
             .playNext,
             .queueEntryRemoveRequested,
             .reorderUpcoming,
             .stop:
          state.pendingLibraryPlayNowOrigin = nil
        default:
          break
        }
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setPlaylistDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        state.library.setPlaylistDetailPlaybackFailure(state.playback.failure)
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
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setPlaylistDetailPlaybackSession(state.playback.session)
        return .send(.playback(.saveCachedSession))

      case .setup:
        return .none
      }
    }
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
      state.library.setAlbumDetailPlaybackSession(state.playback.session)
      state.library.setPlaylistDetailPlaybackSession(state.playback.session)
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
