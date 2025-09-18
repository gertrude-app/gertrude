import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

@Reducer
struct NowPlayingFeature: Downloader {
  @ObservableState
  struct State: Equatable {
    @Fetch(NowPlaying()) var data: NowPlaying.Value = nil
  }

  enum Action: Equatable {
    case view(NowPlayingView.Event)
    case system(AudioPlayer.SystemEvent)
    case episodePlayPauseTapped(Episode, Show)
  }

  @Dependency(\.defaultDatabase) var db
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.audioPlayer) var audioPlayer
  @Dependency(\.date) var date

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        guard let nowPlaying = state.data else {
          unexpected(id: "70012cf6")
          return .none
        }
        switch viewAction {
        case .miniPlayerTapped, .dismissed:
          nowPlaying.updateState { $0.minimized.toggle() }
          return .none
        case .playPauseTapped:
          nowPlaying.updateState { $0.isPlaying.toggle() }
          return .none
        case .scrubbed(to: let position):
          return self.scrub(nowPlaying, to: position)
        case .skipBackwardTapped:
          return self.skip(nowPlaying, .backward, amount: 15)
        case .skipForwardTapped:
          return self.skip(nowPlaying, .forward, amount: 30)
        }
      case .system(let event):
        guard let nowPlaying = state.data else {
          unexpected(id: "9faa5b69")
          return .none
        }
        switch event {
        case .play(let time):
          nowPlaying.updateState { $0.isPlaying = true }
          time.map { nowPlaying.setProgress($0) }
          return .none
        case .pause(let time):
          nowPlaying.updateState { $0.isPlaying = false }
          time.map { nowPlaying.setProgress($0) }
          return .none
        case .progressUpdated(let time):
          nowPlaying.setProgress(time)
          return .none
        case .scrubbed(to: let position):
          return self.scrub(nowPlaying, to: position)
        case .skippedBackward(from: let location, amount: let amount):
          return self.skip(nowPlaying, .backward, amount: amount, from: location)
        case .skippedForward(from: let location, amount: let amount):
          return self.skip(nowPlaying, .forward, amount: amount, from: location)
        }
      case .episodePlayPauseTapped(let episode, let show):
        return .run { [state] _ in
          await self.ensureDownloaded(episode: episode)
          if state.data?.episode.id == episode.id {
            state.data?.updateState { $0.isPlaying.toggle() }
          } else {
            if state.data?.state.isPlaying == true,
               let finalPosition = await self.audioPlayer.getPlayingPosition() {
              state.data?.setProgress(finalPosition)
            }
            NowPlaying.set(
              episode: episode,
              show: show,
              state: .init(isPlaying: true, minimized: true)
            )
          }
        }
      }
    }
  }

  enum SkipDirection {
    case forward
    case backward
  }

  func skip(
    _ nowPlaying: NowPlaying.Data,
    _ direction: SkipDirection,
    amount: Double,
    from location: Double? = nil,
  ) -> Effect<Action> {
    .run { _ in
      var currentLoc = location ?? -1.0
      if currentLoc < 0 {
        currentLoc = await self.audioPlayer.getPlayingPosition() ?? nowPlaying.episode.progress
      }
      let newTime = switch direction {
      case .forward:
        min(Double(nowPlaying.episode.duration ?? .max), currentLoc + amount)
      case .backward:
        max(0, currentLoc - amount)
      }
      await self.audioPlayer.seek(to: newTime)
      nowPlaying.setProgress(newTime)
    }
  }

  func scrub(_ nowPlaying: NowPlaying.Data, to newTime: Double) -> Effect<Action> {
    .run { _ in
      await self.audioPlayer.seek(to: newTime)
      nowPlaying.setProgress(newTime)
    }
  }
}
