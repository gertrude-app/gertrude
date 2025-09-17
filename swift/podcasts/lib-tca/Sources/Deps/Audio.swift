import AVFoundation
import Combine
import Dependencies
import DependenciesMacros
import Foundation
import MediaPlayer
import Synchronization

@DependencyClient
struct AudioPlayer: Sendable {
  enum ExternalEvent: Equatable, Sendable {
    case play(Double?)
    case pause(Double?)
    case scrubbedTo(Double)
    case progressUpdated(Double)
    case skippedForward(Double)
    case skippedBackward(Double)
  }

  var play: @Sendable (_ episode: Episode, _ show: Show) async throws -> Void
  var pause: @Sendable () async throws -> Void
  var externalEvents: @Sendable () -> AnyPublisher<ExternalEvent, Never> = {
    Empty().eraseToAnyPublisher()
  }
}

extension AudioPlayer: DependencyKey {
  public static var liveValue: AudioPlayer {
    AudioPlayer(
      play: { episode, show in
        try sharedPlayer.withLock { try $0.play(episode, show) }
      },
      pause: {
        sharedPlayer.withLock { $0.pause() }
      },
      externalEvents: {
        sharedPlayer.withLock { $0.events() }
      }
    )
  }
}

private let sharedPlayer = Mutex(Player())

private final class Player: Sendable {
  private let player: Mutex<AVPlayer?> = Mutex(nil)
  private let episode: Mutex<Episode?> = Mutex(nil)
  private let timer: Mutex<Any?> = Mutex(nil)
  private let subject = Mutex(PassthroughSubject<AudioPlayer.ExternalEvent, Never>())

  init() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback)
    try? session.setMode(.spokenAudio)
    try? session.setActive(true)
    self.setupRemoteCommands()
  }

  deinit {
    self.stopTimeUpdates()
  }

  func play(_ episode: Episode, _ show: Show) throws {
    if self.episode.withLock({ $0?.id }) == episode.id {
      self.player.play()
    } else {
      self.player.withLock { $0 = AVPlayer(url: episode.localAudioUrl) }
      self.player.play()
    }
    self.episode.withLock { $0 = episode }
    self.updateNowPlayingInfo(episode: episode, show: show)
    self.startTimeUpdates()
  }

  func pause() {
    self.player.pause()
    self.stopTimeUpdates()
  }

  func events() -> AnyPublisher<AudioPlayer.ExternalEvent, Never> {
    self.subject.withLock { $0.eraseToAnyPublisher() }
  }

  private func updateNowPlayingInfo(episode: Episode, show: Show) {
    var nowPlayingInfo: [String: Any] = [
      MPMediaItemPropertyTitle: episode.title,
      MPMediaItemPropertyArtist: show.name,
      MPMediaItemPropertyAlbumTitle: show.name,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: self.player.currentTime ?? 0.0,
      MPNowPlayingInfoPropertyPlaybackRate: self.player.isPlaying ? 1.0 : 0.0,
    ]
    if let duration = episode.duration {
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = TimeInterval(duration)
    }
    if let artwork = show.localArtworkImage {
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork.mediaItemArtwork
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func setupRemoteCommands() {
    let commands = MPRemoteCommandCenter.shared()
    commands.playCommand.removeTarget(nil)
    commands.pauseCommand.removeTarget(nil)
    commands.changePlaybackPositionCommand.removeTarget(nil)
    commands.skipBackwardCommand.removeTarget(nil)
    commands.skipForwardCommand.removeTarget(nil)

    self.setupRemotePlayCommand()
    self.setupRemotePauseCommand()
    self.setupRemotePositionCommand()
    self.setupRemoteSkipBackwardCommand()
    self.setupRemoteSkipForwardCommand()
  }

  private func setupRemotePlayCommand() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
      let position = self?.player.play()
      self?.startTimeUpdates()
      self?.subject.withLock { $0.send(.play(position)) }
      return .success
    }
  }

  private func setupRemotePauseCommand() {
    MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
      let position = self?.player.pause()
      self?.stopTimeUpdates()
      self?.subject.withLock { $0.send(.pause(position)) }
      return .success
    }
  }

  private func setupRemotePositionCommand() {
    let commands = MPRemoteCommandCenter.shared()
    commands.changePlaybackPositionCommand.isEnabled = true
    commands.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self, self.player.withLock({ $0 != nil }),
            let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }

      self.player.withLock {
        $0?.seek(to: CMTime(seconds: positionEvent.positionTime, preferredTimescale: 30))
      }

      self.subject.withLock {
        $0.send(.scrubbedTo(positionEvent.positionTime))
      }

      self.updateElapsedTime()
      return .success
    }
  }

  private func setupRemoteSkipBackwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    commands.skipBackwardCommand.isEnabled = true
    commands.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
    commands.skipBackwardCommand.addTarget { [weak self] _ in
      guard let self, let currentTime = self.player.currentTime else {
        return .commandFailed
      }

      let newTime = max(0, currentTime - 15)
      self.player.withLock {
        $0?.seek(to: CMTime(seconds: newTime, preferredTimescale: 30))
      }

      self.subject.withLock {
        $0.send(.skippedBackward(newTime))
      }

      self.updateElapsedTime()
      return .success
    }
  }

  private func setupRemoteSkipForwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    commands.skipForwardCommand.isEnabled = true
    commands.skipForwardCommand.preferredIntervals = [NSNumber(value: 30)]
    commands.skipForwardCommand.addTarget { [weak self] _ in
      guard let self, let currentTime = self.player.currentTime else {
        return .commandFailed
      }

      let newTime = min(
        self.episode.withLock { $0 }?.duration.flatMap { Double($0) } ?? .infinity,
        currentTime + 30
      )

      self.player.withLock {
        $0?.seek(to: CMTime(seconds: newTime, preferredTimescale: 30))
      }

      self.subject.withLock {
        $0.send(.skippedForward(newTime))
      }

      self.updateElapsedTime()
      return .success
    }
  }

  private func startTimeUpdates() {
    self.stopTimeUpdates()
    let token: Any? = self.player.withLock {
      guard let player = $0 else { return nil }
      return player.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 5.0, preferredTimescale: 1),
        queue: .main
      ) { [weak self] time in
        self?.subject.withLock { $0.send(.progressUpdated(time.seconds)) }
        self?.updateElapsedTime()
      }
    }
    self.setTimer(token: token)
  }

  private func setTimer(token: sending Any?) {
    // HACK: https://forums.swift.org/t/mutex-error/76653/3
    let workaround = { token }
    self.timer.withLock { $0 = workaround() }
  }

  private func stopTimeUpdates() {
    if let token = self.timer.withLock({ $0 }) {
      self.player.withLock { $0?.removeTimeObserver(token) }
      self.setTimer(token: nil)
    }
  }

  private func updateElapsedTime() {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.isPlaying ? 1.0 : 0.0
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime ?? 0.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
}

extension Mutex<AVPlayer?> {
  @discardableResult
  func play() -> Double? {
    self.withLock {
      guard let player = $0 else { return nil }
      player.play()
      return player.currentTime().seconds
    }
  }

  @discardableResult
  func pause() -> Double? {
    self.withLock {
      guard let player = $0 else { return nil }
      player.pause()
      return player.currentTime().seconds
    }
  }

  var isPlaying: Bool {
    self.withLock { $0?.timeControlStatus == .playing }
  }

  var currentTime: TimeInterval? {
    self.withLock { $0?.currentTime().seconds }
  }
}

extension DependencyValues {
  var audioPlayer: AudioPlayer {
    get { self[AudioPlayer.self] }
    set { self[AudioPlayer.self] = newValue }
  }
}
