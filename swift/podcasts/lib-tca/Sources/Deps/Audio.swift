import AVFoundation
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct AudioPlayer: Sendable {
  var playEpisodeAudio: @Sendable (_ episode: Episode) async throws -> Void
}

extension AudioPlayer: DependencyKey {
  public static var liveValue: AudioPlayer {
    AudioPlayer(
      playEpisodeAudio: { episode in
        #if os(iOS)
          let audioSession = AVAudioSession.sharedInstance()
          try? audioSession.setCategory(
            .playback,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay]
          )
          try? audioSession.setActive(true)
        #endif
        Task { @MainActor in
          player = try AVAudioPlayer(contentsOf: episode.localAudioUrl)
          player?.prepareToPlay()
          player?.play()
        }
      },
    )
  }
}

extension DependencyValues {
  var audioPlayer: AudioPlayer {
    get { self[AudioPlayer.self] }
    set { self[AudioPlayer.self] = newValue }
  }
}

@MainActor private var player: AVAudioPlayer?
