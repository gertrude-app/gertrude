import ComposableArchitecture
import GertieApp
import GertieTcaFeatures

@Reducer
struct AppFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var killSwitch = KillSwitchFeature.State()
    var library = LibraryFeature.State()
    var playback = PlaybackFeature.State()
    var setup = MusicSetupFeature.State()
    var isNowPlayingPresented = false
  }

  enum Action: Equatable {
    case killSwitch(KillSwitchFeature.Action)
    case library(LibraryFeature.Action)
    case nowPlayingAlbumInfoTapped
    case nowPlayingPresentationChanged(Bool)
    case playback(PlaybackFeature.Action)
    case setup(MusicSetupFeature.Action)
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
          replacingCurrent: true,
        ) else { return .none }
        state.isNowPlayingPresented = false
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        return .none

      case .killSwitch:
        return .none

      case .nowPlayingPresentationChanged(let isPresented):
        state.isNowPlayingPresented = isPresented
        return .none

      case .library(.debugResetOnboardingButtonTapped):
        self.keychain.deleteConnection()
        self.keychain.save(deviceId: self.uuid())
        state.isNowPlayingPresented = false
        state.library = .init()
        state.playback = .init()
        state.setup = .init()
        return .merge(
          .cancel(id: MusicSetupFeature.CancelID.musicAppStatusPolling),
          .cancel(id: PlaybackFeature.CancelID.playbackEvents),
          .run { _ in await self.playback.stop() },
        )

      case .library(.delegate(.dismissPlaybackFailure)):
        return .send(.playback(.playbackFailureDismissed))

      case .library(.delegate(.playbackFailureActionTapped)):
        return .send(.playback(.playbackFailureActionTapped))

      case .library(.delegate(.playAlbum(let items, let startIndex))):
        return .send(.playback(.playAlbumQueue(items: items, startIndex: startIndex)))

      case .library(.delegate(.togglePlayPause)):
        return .send(.playback(.togglePlayPause))

      case .library:
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        return .none

      case .playback:
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
        return .none

      case .setup:
        return .none
      }
    }
  }
}
