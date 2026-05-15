import AVFoundation
import Combine
import Dependencies
import DependenciesMacros
import Foundation
import LibCore
import MediaPlayer
import XCore

@DependencyClient
struct AudioPlayer: Sendable {
  var play: @Sendable (_ episode: Episode, _ show: Show) async throws -> Void
  var pause: @Sendable () async -> Void
  var seek: @Sendable (_ to: Double) async -> Void = { _ in }
  var setPlaybackRate: @Sendable (_ rate: Double) async -> Void = { _ in }
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
    case headphonesDoubleClickReceived(position: Double?)
    case headphonesTripleClickReceived(position: Double?)
    case completed
    case interruptionBegan(position: Double?)
    case interruptionEnded(shouldResume: Bool, from: Double?)
  }
}

extension AudioPlayer: DependencyKey {
  static var liveValue: AudioPlayer {
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
      setPlaybackRate: { rate in
        sharedPlayer.withLock { $0.setPlaybackRate(rate) }
      },
      getPlayingPosition: {
        sharedPlayer.withLock { $0.player.currentTime }
      },
      systemEvents: {
        sharedPlayer.withLock { $0.events() }
      },
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
  private let playbackRate: Mutex<Double> = Mutex(1.0)
  private let subject = Mutex(PassthroughSubject<AudioPlayer.SystemEvent, Never>())
  private let completionObserver: Locked<Any?> = Locked(nil)
  private let interruptionObserver: Locked<Any?> = Locked(nil)

  init() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
    self.setupRemoteCommands()
    self.setupInterruptionObserver()
  }

  deinit {
    self.player.stopTimeUpdates()
    self.removeCompletionObserver()
    self.removeInterruptionObserver()
  }

  func play(_ episode: Episode, _ show: Show) throws {
    try? AVAudioSession.sharedInstance().setActive(true)
    if self.episode.withLock({ $0?.id }) == episode.id {
      self.player.play()
    } else {
      try self.player.play(new: episode)
      self.setupCompletionObserver()
    }
    self.applyStoredRate()
    self.episode.withLock { $0 = episode }
    self.updateNowPlayingInfo(episode: episode, show: show)
    self.startTimeUpdates()
  }

  private func applyStoredRate() {
    let rate = self.playbackRate.withLock { $0 }
    self.player.withLock { $0?.player.rate = Float(rate) }
  }

  func setPlaybackRate(_ rate: Double) {
    self.playbackRate.withLock { $0 = rate }
    self.player.withLock {
      guard $0?.player.timeControlStatus == .playing else { return }
      $0?.player.rate = Float(rate)
    }
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
    let rate = self.playbackRate.withLock { $0 }
    var nowPlayingInfo: [String: Any] = [
      MPMediaItemPropertyTitle: episode.title,
      MPMediaItemPropertyArtist: show.name,
      MPMediaItemPropertyAlbumTitle: show.name,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: self.player.currentTime ?? 0.0,
      MPNowPlayingInfoPropertyPlaybackRate: self.player.isPlaying ? rate : 0.0,
    ]
    if let duration = episode.duration {
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = TimeInterval(duration)
    }
    let artworkImage = show.localArtworkImage ?? UIImage(named: "artwork")
    if let artwork = artworkImage {
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
    commands.nextTrackCommand.removeTarget(nil)
    commands.previousTrackCommand.removeTarget(nil)

    self.setupRemotePlayCommand()
    self.setupRemotePauseCommand()
    self.setupRemoteSkipBackwardCommand()
    self.setupRemoteSkipForwardCommand()
    self.setupRemoteScrubCommand()
    self.setupHeadphoneCommands()
  }

  private func setupRemotePlayCommand() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
      try? AVAudioSession.sharedInstance().setActive(true)
      let position = self?.player.play()
      self?.applyStoredRate()
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

  private func setupHeadphoneCommands() {
    let commands = MPRemoteCommandCenter.shared()

    commands.nextTrackCommand.isEnabled = true
    commands.nextTrackCommand.addTarget { [weak self] _ in
      self?.emit(.headphonesDoubleClickReceived(position: self?.player.currentTime))
      return .success
    }

    commands.previousTrackCommand.isEnabled = true
    commands.previousTrackCommand.addTarget { [weak self] _ in
      self?.emit(.headphonesTripleClickReceived(position: self?.player.currentTime))
      return .success
    }
  }

  private func startTimeUpdates() {
    self.player.stopTimeUpdates()
    self.player.withLock {
      guard let data = $0 else { return }
      let token = data.player.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 1.0, preferredTimescale: 1),
        queue: .main,
      ) { [weak self] time in
        self?.emit(.progressUpdated(time.seconds))
        self?.updateElapsedTime()
      }
      $0?.timer = token
    }
  }

  private func updateElapsedTime() {
    let rate = self.playbackRate.withLock { $0 }
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.isPlaying ? rate : 0.0
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime ?? 0.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func emit(_ event: AudioPlayer.SystemEvent) {
    self.subject.withLock { $0.send(event) }
  }

  private func setupCompletionObserver() {
    self.removeCompletionObserver()
    guard let playerItem = self.player.withLock({ $0?.player.currentItem }) else { return }
    let observer = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main,
    ) { [weak self] _ in
      self?.emit(.completed)
    }
    self.completionObserver.replace(with: observer)
  }

  private func removeCompletionObserver() {
    self.completionObserver.withValue {
      if let observer = $0 {
        NotificationCenter.default.removeObserver(observer)
      }
    }
    self.completionObserver.replace(with: nil)
  }

  private func setupInterruptionObserver() {
    let observer = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance(),
      queue: .main,
    ) { [weak self] notification in
      guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
        return
      }

      switch type {
      case .began:
        self?.emit(.interruptionBegan(position: self?.player.currentTime))
      case .ended:
        let shouldResume: Bool
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
          let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
          shouldResume = options.contains(.shouldResume)
        } else {
          shouldResume = false
        }
        if shouldResume {
          try? AVAudioSession.sharedInstance().setActive(true)
        }
        self?.emit(.interruptionEnded(
          shouldResume: shouldResume,
          from: self?.player.currentTime,
        ))
      @unknown default:
        break
      }
    }
    self.interruptionObserver.replace(with: observer)
  }

  private func removeInterruptionObserver() {
    self.interruptionObserver.withValue {
      if let observer = $0 {
        NotificationCenter.default.removeObserver(observer)
      }
    }
    self.interruptionObserver.replace(with: nil)
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

  func play(new episode: Episode) throws {
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
  var audio: AudioPlayer {
    get { self[AudioPlayer.self] }
    set { self[AudioPlayer.self] = newValue }
  }
}

private class Locked<T>: @unchecked Sendable {
  private var _value: T
  private let lock = NSLock()

  init(_ value: T) {
    self._value = value
  }

  func withValue<R: Sendable>(_ closure: (T) throws -> R) rethrows -> R {
    self.lock.lock()
    defer { lock.unlock() }
    return try closure(self._value)
  }

  func replace(_ closure: @Sendable () -> T) {
    self.lock.lock()
    defer { lock.unlock() }
    self._value = closure()
  }

  @discardableResult
  func replace(with value: T) -> T {
    self.lock.lock()
    defer { lock.unlock() }
    let previous = self._value
    self._value = value
    return previous
  }
}
