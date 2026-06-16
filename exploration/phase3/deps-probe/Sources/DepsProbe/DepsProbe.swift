import Dependencies
import Foundation

struct AudioPlayerClient {
    var play: @Sendable (URL) async throws -> Void
    var stop: @Sendable () async -> Void
    var currentTime: @Sendable () async -> TimeInterval
}

extension AudioPlayerClient: DependencyKey {
    static let liveValue = AudioPlayerClient(
        play: { _ in },
        stop: {},
        currentTime: { 0.0 }
    )

    static let testValue = AudioPlayerClient(
        play: { _ in },
        stop: {},
        currentTime: { 42.0 }
    )
}

extension DependencyValues {
    var audioPlayer: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}

struct EpisodeService {
    @Dependency(\.audioPlayer) var audioPlayer

    func playEpisode(url: URL) async throws {
        try await audioPlayer.play(url)
    }
}
