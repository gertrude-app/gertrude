import ComposableArchitecture
import Foundation

@Reducer
struct MusicPocFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var status = MusicPocStatus.needsAuthorization
  }

  enum Action: Equatable {
    case authorizeButtonTapped
    case authorizationResponse(Bool)
    case authorizationFailed
    case playButtonTapped
    case playResponse
    case playFailed
  }

  @Dependency(\.appleMusic) var appleMusic

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .authorizeButtonTapped:
        state.status = .authorizing
        return .run { send in
          do {
            await send(.authorizationResponse(try await self.appleMusic.requestAuthorization()))
          } catch {
            await send(.authorizationFailed)
          }
        }

      case .authorizationResponse(true):
        state.status = .readyToPlay
        return .none

      case .authorizationResponse(false):
        state.status = .denied
        return .none

      case .authorizationFailed:
        state.status = .failed(MusicPocError.authorizationFailed.message)
        return .none

      case .playButtonTapped:
        return .run { send in
          do {
            try await self.appleMusic.playTestSong()
            await send(.playResponse)
          } catch {
            await send(.playFailed)
          }
        }

      case .playResponse:
        state.status = .playing
        return .none

      case .playFailed:
        state.status = .failed(MusicPocError.playbackFailed.message)
        return .none
      }
    }
  }
}

enum MusicPocStatus: Equatable {
  case needsAuthorization
  case authorizing
  case readyToPlay
  case playing
  case denied
  case failed(String)
}

enum MusicPocError: Error, Equatable {
  case authorizationFailed
  case playbackFailed

  var message: String {
    switch self {
    case .authorizationFailed:
      "Unable to authorize Apple Music."
    case .playbackFailed:
      "Unable to start playback."
    }
  }
}
