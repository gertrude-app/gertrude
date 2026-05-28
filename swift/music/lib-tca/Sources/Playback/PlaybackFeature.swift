import ComposableArchitecture

@Reducer
struct PlaybackFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var status = Status.stopped
  }

  enum Status: Equatable {
    case stopped
    case playingTrack(PlaybackItem)
    case playingTracksInOrder([PlaybackItem])
  }

  enum Action: Equatable {
    case playTrack(PlaybackItem)
    case playTracksInOrder([PlaybackItem])
    case stop
    case playbackFailed
  }

  @Dependency(\.playback) var playback

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .playTrack(let item):
        state.status = .playingTrack(item)
        return .run { send in
          do {
            try await self.playback.playTrack(item)
          } catch {
            await send(.playbackFailed)
          }
        }

      case .playTracksInOrder(let items):
        guard !items.isEmpty else { return .none }
        state.status = .playingTracksInOrder(items)
        return .run { send in
          do {
            try await self.playback.playTracksInOrder(items)
          } catch {
            await send(.playbackFailed)
          }
        }

      case .stop:
        state.status = .stopped
        return .run { _ in
          await self.playback.stop()
        }

      case .playbackFailed:
        state.status = .stopped
        return .none
      }
    }
  }
}

extension PlaybackFeature.Status {
  var currentTrackID: ApprovedTrack.ID? {
    switch self {
    case .stopped:
      nil
    case .playingTrack(let item):
      item.id
    case .playingTracksInOrder(let items):
      items.first?.id
    }
  }
}
