import ComposableArchitecture
import Foundation

@Reducer
struct MusicPocFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var status = MusicPocStatus.needsAuthorization
    var track = DemoTrack.track
    var blocksArtwork = false
    var isPlaying = false
    var isStarting = false
  }

  enum Action: Equatable {
    case authorizeButtonTapped
    case authorizationResponse(Bool)
    case authorizationFailed
    case artworkBlockingChanged(Bool)
    case playPauseButtonTapped
    case playResponse
    case pauseResponse
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

      case .artworkBlockingChanged(let blocksArtwork):
        state.blocksArtwork = blocksArtwork
        guard state.isPlaying else {
          return .none
        }
        state.isStarting = true
        let track = state.track
        return .run { send in
          do {
            try await self.appleMusic.playSong(track.id, blocksArtwork)
            await send(.playResponse)
          } catch {
            await send(.playFailed)
          }
        }

      case .playPauseButtonTapped:
        if state.isPlaying {
          state.isPlaying = false
          state.isStarting = false
          return .run { send in
            await self.appleMusic.pause()
            await send(.pauseResponse)
          }
        }
        state.status = .readyToPlay
        state.isStarting = true
        let track = state.track
        let blocksArtwork = state.blocksArtwork
        return .run { send in
          do {
            try await self.appleMusic.playSong(track.id, blocksArtwork)
            await send(.playResponse)
          } catch {
            await send(.playFailed)
          }
        }

      case .playResponse:
        state.status = .readyToPlay
        state.isPlaying = true
        state.isStarting = false
        return .none

      case .pauseResponse:
        return .none

      case .playFailed:
        state.isStarting = false
        state.status = .failed(MusicPocError.playbackFailed.message)
        return .none
      }
    }
  }
}

struct DemoTrack: Equatable, Sendable {
  let id: String
  let title: String
  let artist: String
  let artworkURL: URL?

  static let track = Self(
    id: "1758369112",
    title: "See You Again",
    artist: "The Gray Havens",
    artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/75/1d/a6/751da645-a25f-3545-9871-93c94cc3d658/12453.jpg/600x600bb.jpg"),
  )
}

enum MusicPocStatus: Equatable {
  case needsAuthorization
  case authorizing
  case readyToPlay
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
