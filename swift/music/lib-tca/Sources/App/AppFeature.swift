import ComposableArchitecture
import Foundation
import MusicRoute

@Reducer
struct AppFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var library = LibraryFeature.State()
    var playback = PlaybackFeature.State()
    var connection = ConnectionStatus.checking
    var searchText = ""
    var isNowPlayingPresented = false

    enum ConnectionStatus: Equatable {
      case checking
      case unclaimed(code: Int, expiresAt: Date)
      case claimed(childName: String)
      case failed
    }
  }

  enum Action: Equatable {
    case onAppear
    case refreshConnectionTapped
    case musicAppStatusLoaded(GetMusicAppStatus.Output)
    case musicAppStatusFailed(hasStoredConnection: Bool)
    case library(LibraryFeature.Action)
    case playback(PlaybackFeature.Action)
    case searchTextChanged(String)
    case nowPlayingPresentationChanged(Bool)
  }

  @Dependency(\.api) var api
  @Dependency(\.keychain) var keychain

  var body: some ReducerOf<Self> {
    Scope(state: \.library, action: \.library) {
      LibraryFeature()
    }

    Scope(state: \.playback, action: \.playback) {
      PlaybackFeature()
    }

    Reduce { state, action in
      switch action {
      case .onAppear, .refreshConnectionTapped:
        let storedConnection = self.keychain.loadConnection()
        if let storedConnection {
          state.connection = .claimed(childName: storedConnection.childName)
        } else {
          state.connection = .checking
        }
        return .run { send in
          do {
            let status = try await self.api.getMusicAppStatus()
            await send(.musicAppStatusLoaded(status))
          } catch {
            await send(.musicAppStatusFailed(hasStoredConnection: storedConnection != nil))
          }
        }

      case .musicAppStatusLoaded(.unclaimed(let code, let expiresAt)):
        self.keychain.deleteConnection()
        state.connection = .unclaimed(code: code, expiresAt: expiresAt)
        return .none

      case .musicAppStatusLoaded(.claimed(let token, let childId, let childName)):
        self.keychain.save(connection: .init(
          token: token,
          childId: childId,
          childName: childName,
        ))
        state.connection = .claimed(childName: childName)
        return .none

      case .musicAppStatusFailed(let hasStoredConnection):
        if !hasStoredConnection {
          state.connection = .failed
        }
        return .none

      case .searchTextChanged(let searchText):
        state.searchText = searchText
        return .none

      case .nowPlayingPresentationChanged(let isPresented):
        state.isNowPlayingPresented = isPresented
        return .none

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
      }
    }
  }
}
