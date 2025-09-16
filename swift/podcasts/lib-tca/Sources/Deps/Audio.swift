import AVFoundation
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct AudioPlayer: Sendable {
  var play: @Sendable (_ episode: Episode, _ show: Show) async throws -> Void
  var pause: @Sendable () async throws -> Void
}

extension AudioPlayer: DependencyKey {
  public static var liveValue: AudioPlayer {
    AudioPlayer(
      play: { episode, show in
        try await Player.shared.play(episode: episode)
      },
      pause: {
        await Player.shared.pause()
      },
    )
  }
}

private actor Player {
  static let shared = Player()
  private var player: AVAudioPlayer?
  private var episode: Episode?

  init() {
    #if os(iOS)
      try? AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .spokenAudio,
        options: [.allowBluetooth, .allowAirPlay]
      )
      try? AVAudioSession.sharedInstance().setActive(true)
    #endif
  }

  func play(episode: Episode) throws {
    if self.episode?.id == episode.id {
      self.player?.play()
    } else {
      self.player = try AVAudioPlayer(contentsOf: episode.localAudioUrl)
      self.player?.prepareToPlay() // necessary?
      self.player?.play()
    }
    self.episode = episode
  }

  func pause() {
    self.player?.pause()
  }
}

@MainActor private var player: AVAudioPlayer?

extension DependencyValues {
  var audioPlayer: AudioPlayer {
    get { self[AudioPlayer.self] }
    set { self[AudioPlayer.self] = newValue }
  }
}
