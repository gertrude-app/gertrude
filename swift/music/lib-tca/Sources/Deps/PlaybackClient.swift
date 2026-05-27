import Dependencies
import DependenciesMacros
import Foundation
import MusicKit

#if os(iOS)
  import AVFoundation
  import Darwin
#endif

@DependencyClient
struct PlaybackClient: Sendable {
  var playTrack: @Sendable (_ item: PlaybackItem) async throws -> Void
  var playTracksInOrder: @Sendable (_ items: [PlaybackItem]) async throws -> Void
  var stop: @Sendable () async -> Void
}

extension PlaybackClient: DependencyKey {
  static let liveValue = Self.live
  static let testValue = Self.noop
}

extension DependencyValues {
  var playback: PlaybackClient {
    get { self[PlaybackClient.self] }
    set { self[PlaybackClient.self] = newValue }
  }
}

extension PlaybackClient {
  static let live = Self(
    playTrack: { item in
      try await Self.play(items: [item])
    },
    playTracksInOrder: { items in
      try await Self.play(items: items)
    },
    stop: {
      await Self.stopPlayback()
    },
  )

  static let noop = Self(
    playTrack: { _ in },
    playTracksInOrder: { _ in },
    stop: {},
  )

  private static func requestAuthorization() async -> Bool {
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
  }

  @MainActor
  private static func play(items: [PlaybackItem]) async throws {
    guard !items.isEmpty else { return }
    guard await self.requestAuthorization() else {
      throw PlaybackClientError.notAuthorized
    }

    #if os(iOS)
      self.activateAudioSession()
      let hidesArtwork = items.contains { !$0.allowsArtwork }
      MediaRemotePrivateClient.shared.setCanBeNowPlayingApplication(true)
      MediaRemotePrivateClient.shared.setNowPlayingApplicationOverrideEnabled(hidesArtwork)
      if hidesArtwork {
        await self.updateNowPlayingInfo(for: items[0], hidesArtwork: true)
      } else {
        MediaRemotePrivateClient.shared.clearNowPlayingInfo()
      }
    #endif

    let songs = try await self.songs(for: items)
    let player = ApplicationMusicPlayer.shared
    player.queue = ApplicationMusicPlayer.Queue(for: songs)
    try await player.play()

    #if os(iOS)
      if hidesArtwork {
        await self.refreshNowPlayingInfo(for: items[0], hidesArtwork: true)
      }
    #endif
  }

  @MainActor
  private static func stopPlayback() async {
    #if os(iOS)
      MediaRemotePrivateClient.shared.clearNowPlayingInfo()
      MediaRemotePrivateClient.shared.setNowPlayingApplicationOverrideEnabled(false)
    #endif
    ApplicationMusicPlayer.shared.stop()
  }

  #if os(iOS)
    private static func activateAudioSession() {
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.playback, mode: .default)
      try? session.setActive(true)
    }

    @MainActor
    private static func refreshNowPlayingInfo(
      for item: PlaybackItem,
      hidesArtwork: Bool,
    ) async {
      try? await Task.sleep(nanoseconds: 250_000_000)
      await self.updateNowPlayingInfo(for: item, hidesArtwork: hidesArtwork)
      try? await Task.sleep(nanoseconds: 750_000_000)
      await self.updateNowPlayingInfo(for: item, hidesArtwork: hidesArtwork)
    }

    @MainActor
    private static func updateNowPlayingInfo(
      for item: PlaybackItem,
      hidesArtwork: Bool,
    ) async {
      let loadedArtwork = if !hidesArtwork,
        item.allowsArtwork,
        let artworkURL = item.artworkURL
      {
        await self.artwork(for: artworkURL)
      } else {
        Optional<LoadedArtwork>.none
      }

      MediaRemotePrivateClient.shared.setNowPlayingInfo(
        title: item.title,
        artist: item.artistName,
        artwork: loadedArtwork,
      )
    }

    private static func artwork(for url: URL) async -> LoadedArtwork? {
      do {
        let (data, response) = try await URLSession.shared.data(from: url)
        let mimeType = response.mimeType ?? "image/jpeg"
        return LoadedArtwork(data: data, mimeType: mimeType)
      } catch {
        return nil
      }
    }

  #endif

  private static func songs(for items: [PlaybackItem]) async throws -> [Song] {
    var songs: [Song] = []
    for item in items {
      let songId = MusicItemID(item.id.rawValue)
      let request = MusicCatalogResourceRequest<Song>(
        matching: \.id,
        equalTo: songId,
      )
      let response = try await request.response()
      guard let song = response.items.first else {
        throw PlaybackClientError.trackNotFound
      }
      songs.append(song)
    }
    return songs
  }
}

#if os(iOS)
  private struct LoadedArtwork {
    let data: Data
    let mimeType: String
  }

  @MainActor
  private final class MediaRemotePrivateClient {
    static let shared = MediaRemotePrivateClient()

    private let handle: UnsafeMutableRawPointer?

    private init() {
      handle = dlopen(
        "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
        RTLD_NOW,
      )
    }

    func setCanBeNowPlayingApplication(_ canBeNowPlaying: Bool) {
      guard let handle,
            let symbol = dlsym(handle, "MRMediaRemoteSetCanBeNowPlayingApplication")
      else {
        return
      }
      typealias Function = @convention(c) (UInt8) -> Void
      unsafeBitCast(symbol, to: Function.self)(canBeNowPlaying ? 1 : 0)
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

    func setNowPlayingInfo(
      title: String,
      artist: String,
      artwork: LoadedArtwork?,
    ) {
      guard let handle,
            let symbol = dlsym(handle, "MRMediaRemoteSetNowPlayingInfo")
      else {
        return
      }

      var info: [CFString: Any] = [:]
      self.set("kMRMediaRemoteNowPlayingInfoTitle", title as NSString, in: &info)
      self.set("kMRMediaRemoteNowPlayingInfoArtist", artist as NSString, in: &info)
      self.set("kMRMediaRemoteNowPlayingInfoPlaybackRate", NSNumber(value: 1), in: &info)
      self.set("kMRMediaRemoteNowPlayingInfoElapsedTime", NSNumber(value: 0), in: &info)
      self.set("kMRMediaRemoteNowPlayingInfoDuration", NSNumber(value: 0), in: &info)
      if let artwork {
        self.set("kMRMediaRemoteNowPlayingInfoArtworkData", artwork.data as NSData, in: &info)
        self.set("kMRMediaRemoteNowPlayingInfoArtworkMIMEType", artwork.mimeType as NSString, in: &info)
      }

      typealias Function = @convention(c) (CFDictionary) -> Void
      unsafeBitCast(symbol, to: Function.self)(info as CFDictionary)
    }

    func clearNowPlayingInfo() {
      guard let handle,
            let symbol = dlsym(handle, "MRMediaRemoteSetNowPlayingInfo")
      else {
        return
      }
      typealias Function = @convention(c) (CFDictionary) -> Void
      unsafeBitCast(symbol, to: Function.self)([:] as CFDictionary)
    }

    private func set(
      _ symbolName: String,
      _ value: Any,
      in info: inout [CFString: Any],
    ) {
      guard let key = self.cfString(symbolName) else { return }
      info[key] = value
    }

    private func cfString(_ symbolName: String) -> CFString? {
      guard let handle,
            let symbol = dlsym(handle, symbolName)
      else {
        return nil
      }
      return symbol.assumingMemoryBound(to: CFString?.self).pointee
    }
  }
#endif

private enum PlaybackClientError: Error {
  case notAuthorized
  case trackNotFound
}
