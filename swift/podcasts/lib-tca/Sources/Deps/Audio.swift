import AVFoundation
import Combine
import Dependencies
import DependenciesMacros
import Foundation
import MediaPlayer
import Synchronization

@DependencyClient
struct AudioPlayer: Sendable {
  var play: @Sendable (_ episode: Episode, _ show: Show) async throws -> Void
  var pause: @Sendable () async throws -> Void
  var seek: @Sendable (_ to: Double) async -> Void = { _ in }
  var getPlayingPosition: @Sendable () async -> Double?
  var systemEvents: @Sendable () -> AnyPublisher<SystemEvent, Never> = {
    Empty().eraseToAnyPublisher()
  }
}

extension AudioPlayer {
  enum SystemEvent: Equatable, Sendable {
    case play(Double?)
    case pause(Double?)
    case scrubbed(to: Double)
    case progressUpdated(Double)
    case skippedForward(from: Double, amount: Double)
    case skippedBackward(from: Double, amount: Double)
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
      seek: { time in
        sharedPlayer.withLock { $0.seek(to: time) }
      },
      getPlayingPosition: {
        sharedPlayer.withLock { $0.player.currentTime }
      },
      systemEvents: {
        sharedPlayer.withLock { $0.events() }
      }
    )
  }
}

private let sharedPlayer = Mutex(Player())

class AVPlayerData {
  let player: AVPlayer
  var timer: Any?

  init(player: AVPlayer, timer: Any? = nil) {
    self.player = player
    self.timer = timer
  }
}

private final class Player: Sendable {
  fileprivate let player: Mutex<AVPlayerData?> = Mutex(nil)
  private let episode: Mutex<Episode?> = Mutex(nil)
  private let timer: Mutex<Any?> = Mutex(nil)
  private let subject = Mutex(PassthroughSubject<AudioPlayer.SystemEvent, Never>())

  init() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback)
    try? session.setMode(.spokenAudio)
    try? session.setActive(true)
    self.setupRemoteCommands()
  }

  deinit {
    self.player.stopTimeUpdates()
  }

  func play(_ episode: Episode, _ show: Show) throws {
    if self.episode.withLock({ $0?.id }) == episode.id {
      self.player.play()
    } else {
      self.player.play(new: episode)
    }
    self.episode.withLock { $0 = episode }
    self.updateNowPlayingInfo(episode: episode, show: show)
    self.startTimeUpdates()
  }

  func pause() {
    self.player.pause()
    self.player.stopTimeUpdates()
  }

  func seek(to time: Double) {
    self.player.seek(to: time)
    self.updateElapsedTime()
  }

  func events() -> AnyPublisher<AudioPlayer.SystemEvent, Never> {
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
    self.setupRemoteSkipBackwardCommand()
    self.setupRemoteSkipForwardCommand()
    self.setupRemoteScrubCommand()
  }

  private func setupRemotePlayCommand() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
      let position = self?.player.play()
      self?.startTimeUpdates()
      self?.emit(.play(position))
      return .success
    }
  }

  private func setupRemotePauseCommand() {
    MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
      let position = self?.player.pause()
      self?.player.stopTimeUpdates()
      self?.emit(.pause(position))
      return .success
    }
  }

  private func setupRemoteScrubCommand() {
    let commands = MPRemoteCommandCenter.shared()
    commands.changePlaybackPositionCommand.isEnabled = true
    commands.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self, self.player.withLock({ $0 != nil }),
            let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }
      self.emit(.scrubbed(to: positionEvent.positionTime))
      return .success
    }
  }

  private func setupRemoteSkipBackwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    commands.skipBackwardCommand.isEnabled = true
    commands.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
    commands.skipBackwardCommand.addTarget { [weak self] event in
      guard let self, let currentTime = self.player.currentTime,
            let skipEvent = event as? MPSkipIntervalCommandEvent else {
        return .commandFailed
      }
      self.emit(.skippedBackward(from: currentTime, amount: skipEvent.interval))
      return .success
    }
  }

  private func setupRemoteSkipForwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    commands.skipForwardCommand.isEnabled = true
    commands.skipForwardCommand.preferredIntervals = [NSNumber(value: 30)]
    commands.skipForwardCommand.addTarget { [weak self] event in
      guard let self, let currentTime = self.player.currentTime,
            let skipEvent = event as? MPSkipIntervalCommandEvent else {
        return .commandFailed
      }
      self.emit(.skippedForward(from: currentTime, amount: skipEvent.interval))
      return .success
    }
  }

  private func startTimeUpdates() {
    self.player.stopTimeUpdates()
    self.player.withLock {
      guard let data = $0 else { return }
      let token = data.player.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 1.0, preferredTimescale: 1),
        queue: .main
      ) { [weak self] time in
        self?.emit(.progressUpdated(time.seconds))
        self?.updateElapsedTime()
      }
      $0?.timer = token
    }
  }

  private func updateElapsedTime() {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.isPlaying ? 1.0 : 0.0
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime ?? 0.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func emit(_ event: AudioPlayer.SystemEvent) {
    self.subject.withLock { $0.send(event) }
  }
}

extension Mutex<AVPlayerData?> {
  @discardableResult
  func play() -> Double? {
    self.withLock {
      guard let player = $0?.player else { return nil }
      player.play()
      return player.currentTime().seconds
    }
  }

  @discardableResult
  func pause() -> Double? {
    self.withLock {
      guard let player = $0?.player else { return nil }
      player.pause()
      return player.currentTime().seconds
    }
  }

  func seek(to time: Double) {
    self.withLock {
      $0?.player.seek(to: CMTime(seconds: time, preferredTimescale: 30))
    }
  }

  func play(new episode: Episode) {
    self.withLock {
      if let current = $0, let token = current.timer {
        current.player.removeTimeObserver(token)
      }
      $0 = nil
      let player = AVPlayer(url: episode.localAudioUrl)
      if episode.progress > 0.0 {
        player.seek(to: CMTime(seconds: episode.progress, preferredTimescale: 30))
      }
      $0 = AVPlayerData(player: player)
      player.play()
    }
  }

  func stopTimeUpdates() {
    self.withLock {
      guard let data = $0,
            let token = data.timer else { return }
      data.player.removeTimeObserver(token)
      data.timer = nil
    }
  }

  var isPlaying: Bool {
    self.withLock { $0?.player.timeControlStatus == .playing }
  }

  var currentTime: TimeInterval? {
    self.withLock { $0?.player.currentTime().seconds }
  }
}

extension DependencyValues {
  var audioPlayer: AudioPlayer {
    get { self[AudioPlayer.self] }
    set { self[AudioPlayer.self] = newValue }
  }
}
