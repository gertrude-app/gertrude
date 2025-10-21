import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct NowPlayingFeature {
  @ObservableState
  struct State: Equatable {
    @Fetch(NowPlaying()) var data: NowPlaying.Value = nil
    @Shared(.appInForeground) var appInForeground
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case alert(String)
    }

    case view(NowPlayingView.Event)
    case system(AudioPlayer.SystemEvent)
    case episodePlayPauseTapped(Episode, Show)
    case delegate(DelegateAction)
  }

  @Dependency(\.db) var database
  @Dependency(\.audio) var audio
  @Dependency(\.haptics) var haptics
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
          NowPlaying.update { $0.minimized.toggle() }
          return .run { _ in
            await self.haptics.prepare()
          }
        case .dismissed:
          NowPlaying.update { $0.minimized.toggle() }
          return .none
        case .playPauseTapped:
          return .run { _ in
            await self.haptics.impact(.light)
            if let time = await self.audio.getPlayingPosition() {
              nowPlaying.setProgress(time)
            }
            NowPlaying.update { $0.isPlaying.toggle() }
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
          NowPlaying.update { $0.isPlaying = true }
          time.map { nowPlaying.setProgress($0) }
          return .none
        case .pause(let time):
          NowPlaying.update { $0.isPlaying = false }
          time.map { nowPlaying.setProgress($0) }
          return .none
        case .progressUpdated(let progress):
          if !state.appInForeground, progress.remainder(dividingBy: 5.0) < 0.1 {
            return .none
          }
          nowPlaying.setProgress(progress)
          return .run { _ in
            if nowPlaying.shouldDownloadNext(at: progress) {
              NowPlaying.update { $0.nextDownloaded = true }
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
          NowPlaying.update { $0.isPlaying = false }
          guard let next = AutoQueue.nextDownloadedEpisode(after: nowPlaying) else {
            NowPlaying.delete()
            return .none
          }
          return .run { _ in
            try? await self.clock.sleep(for: .seconds(3))
            NowPlaying.set(.init(
              episodeId: next.episode.id,
              isPlaying: true,
              minimized: nowPlaying.minimized
            ))
          }
        case .headphonesDoubleClickReceived(let position):
          return self.skip(nowPlaying, .forward, amount: 30, from: position)
        case .headphonesTripleClickReceived(let position):
          return self.skip(nowPlaying, .backward, amount: 15, from: position)
        case .interruptionBegan(let position):
          position.map { nowPlaying.setProgress($0) }
          NowPlaying.update { $0.isPlaying = false }
          return .none
        case .interruptionEnded(shouldResume: true, let position):
          return .run { _ in
            if let position, position >= 5.0 {
              nowPlaying.setProgress(position - 3.0)
              await self.audio.seek(to: position - 3.0)
              NowPlaying.update { $0.isPlaying = true }
            }
          }
        case .interruptionEnded(shouldResume: false, _):
          return .none
        }
      case .episodePlayPauseTapped(let episode, _):
        if let nowPlaying = state.data {
          return self.updateNowPlaying(episode, nowPlaying)
        } else {
          return self.play(episode: episode, previous: nil)
        }
      case .delegate:
        return .none
      }
    }
  }

  func updateNowPlaying(_ episode: Episode, _ nowPlaying: NowPlaying.Data) -> Effect<Action> {
    if episode.id == nowPlaying.episode.id {
      self.toggle(nowPlaying: nowPlaying)
    } else {
      self.play(episode: episode, previous: nowPlaying)
    }
  }

  func toggle(nowPlaying: NowPlaying.Data) -> Effect<Action> {
    if nowPlaying.isPlaying || nowPlaying.episode.downloaded {
      .run { _ in NowPlaying.update { $0.isPlaying.toggle() } }
    } else {
      self.play(episode: nowPlaying.episode, previous: nowPlaying)
    }
  }

  func play(episode: Episode, previous: NowPlaying.Data?) -> Effect<Action> {
    .run { send in
      if previous != nil {
        // write pause to current, to make sure playback stops
        NowPlaying.update { $0.isPlaying = false }
      }
      // initialize new episode to paused, so we can handle possible download
      NowPlaying.set(.init(episodeId: episode.id, isPlaying: false, minimized: true))
      await testAssertCheckpoint("now playing set, initialize to paused")
      if let error = await ensureDownloaded(episode: episode).error {
        await send(.delegate(.alert(error.message)))
        // TODO: delete now playing, i think
      } else {
        NowPlaying.update { $0.isPlaying = true }
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
        currentLoc = await self.audio.getPlayingPosition() ?? nowPlaying.episode.progress
      }
      let newTime = switch direction {
      case .forward:
        min(Double(nowPlaying.episode.duration ?? .max), currentLoc + amount)
      case .backward:
        max(0, currentLoc - amount)
      }
      await self.audio.seek(to: newTime)
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
      await self.audio.seek(to: newTime)
    }
  }
}

extension NowPlayingFeature.State {
  var viewExpanded: Bool { self.data?.minimized == false }
  var expandedViewVisible: Bool { self.viewExpanded && self.appInForeground }
}
