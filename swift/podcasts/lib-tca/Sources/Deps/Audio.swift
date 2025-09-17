import AVFoundation
import Dependencies
import DependenciesMacros
import Foundation
import MediaPlayer
import Synchronization

@DependencyClient
struct AudioPlayer: Sendable {
  var play: @Sendable (_ episode: Episode, _ show: Show) async throws -> Void
  var pause: @Sendable () async throws -> Void
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
    )
  }
}

private let sharedPlayer = Mutex(Player())

private class Player {
  private var player: AVAudioPlayer?
  private var episode: Episode?

  init() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback)
    try? session.setMode(.spokenAudio)
    try? session.setActive(true)
  }

  func play(_ episode: Episode, _ show: Show) throws {
    if self.episode?.id == episode.id {
      self.player?.play()
    } else {
      self.player = try AVAudioPlayer(contentsOf: episode.localAudioUrl)
      self.player?.prepareToPlay()
      self.player?.play()
    }
    self.episode = episode
    self.updateNowPlayingInfo(episode: episode, show: show)
  }

  func pause() {
    self.player?.pause()
  }

  private func updateNowPlayingInfo(episode: Episode, show: Show) {
    var nowPlayingInfo: [String: Any] = [
      MPMediaItemPropertyTitle: episode.title,
      MPMediaItemPropertyAlbumTitle: show.name,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: self.player?.currentTime ?? 0,
      MPNowPlayingInfoPropertyPlaybackRate: self.player?.isPlaying == true ? 1.0 : 0.0,
    ]
    if let duration = episode.duration {
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    }
    if let artwork = show.localArtworkImage {
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork.mediaItemArtwork
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    self.setupRemoteCommands()
  }

  private func setupRemoteCommands() {
    let commands = MPRemoteCommandCenter.shared()
    commands.playCommand.addTarget { [weak self] _ in
      self?.player?.play()
      return .success
    }
    commands.pauseCommand.addTarget { [weak self] _ in
      self?.player?.pause()
      return .success
    }
  }
}

@MainActor private var player: AVAudioPlayer?

extension DependencyValues {
  var audioPlayer: AudioPlayer {
    get { self[AudioPlayer.self] }
    set { self[AudioPlayer.self] = newValue }
  }
}
