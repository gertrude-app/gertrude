import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

@Reducer
struct NowPlayingFeature: Downloader {
  @ObservableState
  struct State: Equatable {
    @Fetch(NowPlaying()) var data: NowPlaying.Value = nil
    @Shared(.appInForeground) var appInForeground
  }

  enum Action: Equatable {
    case view(NowPlayingView.Event)
    case system(AudioPlayer.SystemEvent)
    case episodePlayPauseTapped(Episode, Show)
  }

  @Dependency(\.defaultDatabase) var database
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.audioPlayer) var audioPlayer
  @Dependency(\.date) var date
  @Dependency(\.haptics) var haptics
  @Dependency(\.network) var network
  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        guard let nowPlaying = state.data else {
          unexpected(id: "70012cf6", assert: true)
          return .none
        }
        switch viewAction {
        case .miniPlayerTapped:
          nowPlaying.updateState { $0.minimized.toggle() }
          return .run { _ in
            await self.haptics.prepare()
          }
        case .dismissed:
          nowPlaying.updateState { $0.minimized.toggle() }
          return .none
        case .playPauseTapped:
          return .run { _ in
            await self.haptics.impact(.light)
            if let time = await self.audioPlayer.getPlayingPosition() {
              nowPlaying.setProgress(time)
            }
            nowPlaying.updateState { $0.isPlaying.toggle() }
          }
        case .scrubbed(to: let position):
          return self.scrub(nowPlaying, to: position, haptics: true)
        case .skipBackwardTapped:
          return self.skip(nowPlaying, .backward, amount: 15)
        case .skipForwardTapped:
          return self.skip(nowPlaying, .forward, amount: 30)
        }
      case .system(let event):
        guard let nowPlaying = state.data else {
          unexpected(id: "9faa5b69", assert: true)
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
        case .progressUpdated(let progress):
          nowPlaying.setProgress(progress)
          return .run { _ in
            if nowPlaying.shouldDownloadNext(at: progress) {
              nowPlaying.updateState { $0.nextDownloaded = true }
              await AutoQueue.downloadNextEpisode(after: nowPlaying)
            }
          }
        case .scrubbed(to: let position):
          return self.scrub(nowPlaying, to: position, haptics: false)
        case .skippedBackward(from: let location, amount: let amount):
          return self.skip(nowPlaying, .backward, amount: amount, from: location)
        case .skippedForward(from: let location, amount: let amount):
          return self.skip(nowPlaying, .forward, amount: amount, from: location)
        case .completed:
          nowPlaying.updateState { $0.isPlaying = false }
          guard let next = AutoQueue.nextDownloadedEpisode(after: nowPlaying) else {
            return .none
          }
          return .run { _ in
            try? await self.clock.sleep(for: .seconds(3))
            NowPlaying.set(
              episode: next.episode,
              show: next.show,
              state: .init(isPlaying: true, minimized: nowPlaying.state.minimized,)
            )
          }
        case .headphonesDoubleClickReceived(let position):
          return self.skip(nowPlaying, .forward, amount: 30, from: position)
        case .headphonesTripleClickReceived(let position):
          return self.skip(nowPlaying, .backward, amount: 15, from: position)
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

  func scrub(
    _ nowPlaying: NowPlaying.Data,
    to newTime: Double,
    haptics: Bool = false
  ) -> Effect<Action> {
    .run { _ in
      nowPlaying.setProgress(newTime)
      if haptics {
        await self.haptics.selection()
      }
      await self.audioPlayer.seek(to: newTime)
    }
  }
}

extension NowPlayingFeature.State {
  var viewExpanded: Bool { self.data?.state.minimized == false }
  var expandedViewVisible: Bool { self.viewExpanded && self.appInForeground }
}
