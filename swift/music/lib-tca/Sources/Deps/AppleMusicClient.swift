import Dependencies
import DependenciesMacros
import Foundation
import MusicKit

@DependencyClient
struct AppleMusicClient: Sendable {
  var requestAuthorization: @Sendable () async throws -> Bool
  var playTestSong: @Sendable () async throws -> Void
}

extension AppleMusicClient: DependencyKey {
  static let liveValue = Self.live
}

extension DependencyValues {
  var appleMusic: AppleMusicClient {
    get { self[AppleMusicClient.self] }
    set { self[AppleMusicClient.self] = newValue }
  }
}

extension AppleMusicClient {
  static let live = Self(
    requestAuthorization: {
      switch MusicAuthorization.currentStatus {
      case .authorized:
        return true
      case .denied, .restricted:
        return false
      case .notDetermined:
        return await MusicAuthorization.request() == .authorized
      @unknown default:
        return false
      }
    },
    playTestSong: {
      try await Self.playTestCatalogSong()
    },
  )

  static let mockAuthorized = Self(
    requestAuthorization: { true },
    playTestSong: {},
  )

  static let mockDenied = Self(
    requestAuthorization: { false },
    playTestSong: {},
  )

  @MainActor
  private static func playTestCatalogSong() async throws {
    let songId = MusicItemID("1758369112")
    let request = MusicCatalogResourceRequest<Song>(
      matching: \.id,
      equalTo: songId,
    )
    let response = try await request.response()
    guard let song = response.items.first else {
      throw AppleMusicClientError.testSongNotFound
    }
    let player = ApplicationMusicPlayer.shared
    player.queue = ApplicationMusicPlayer.Queue(for: [song])
    try await player.play()
  }
}

private enum AppleMusicClientError: Error {
  case testSongNotFound
}
