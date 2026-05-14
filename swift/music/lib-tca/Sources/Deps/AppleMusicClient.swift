import Dependencies
import DependenciesMacros
import Foundation
import MusicKit

#if os(iOS)
  import Darwin
  import MediaPlayer
#endif

@DependencyClient
struct AppleMusicClient: Sendable {
  var requestAuthorization: @Sendable () async throws -> Bool
  var playSong: @Sendable (_ id: String, _ blocksArtwork: Bool) async throws -> Void
  var playTestSong: @Sendable () async throws -> Void
  var pause: @Sendable () async -> Void
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
    playSong: { id, blocksArtwork in
      try await Self.playCatalogSong(id: id, blocksArtwork: blocksArtwork)
    },
    playTestSong: {
      try await Self.playCatalogSong(id: "1758369112", blocksArtwork: false)
    },
    pause: {
      await Self.pausePlayback()
    },
  )

  static let mockAuthorized = Self(
    requestAuthorization: { true },
    playSong: { _, _ in },
    playTestSong: {},
    pause: {},
  )

  static let mockDenied = Self(
    requestAuthorization: { false },
    playSong: { _, _ in },
    playTestSong: {},
    pause: {},
  )

  @MainActor
  private static func playCatalogSong(id: String, blocksArtwork: Bool) async throws {
    #if os(iOS)
      let player = MPMusicPlayerController.applicationQueuePlayer
      player.setQueue(with: [id])
      MediaRemotePrivateClient.shared.setNowPlayingApplicationOverrideEnabled(blocksArtwork)
      player.play()
    #else
      let songId = MusicItemID(id)
      let request = MusicCatalogResourceRequest<Song>(
        matching: \.id,
        equalTo: songId,
      )
      let response = try await request.response()
      guard let song = response.items.first else {
        throw AppleMusicClientError.songNotFound
      }
      let player = ApplicationMusicPlayer.shared
      player.queue = ApplicationMusicPlayer.Queue(for: [song])
      try await player.play()
    #endif
  }

  @MainActor
  private static func pausePlayback() async {
    #if os(iOS)
      MPMusicPlayerController.applicationQueuePlayer.pause()
    #else
      ApplicationMusicPlayer.shared.pause()
    #endif
  }
}

#if os(iOS)
  @MainActor
  private final class MediaRemotePrivateClient {
    static let shared = MediaRemotePrivateClient()

    private let handle: UnsafeMutableRawPointer?

    private init() {
      handle = dlopen(
        "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)
    }

    func setNowPlayingApplicationOverrideEnabled(_ enabled: Bool) {
      guard let handle,
        let symbol = dlsym(handle, "MRMediaRemoteSetNowPlayingApplicationOverrideEnabled")
      else {
        return
      }
      typealias Function = @convention(c) (UInt8) -> Void
      unsafeBitCast(symbol, to: Function.self)(enabled ? 1 : 0)
    }
  }
#endif

private enum AppleMusicClientError: Error {
  case songNotFound
}
