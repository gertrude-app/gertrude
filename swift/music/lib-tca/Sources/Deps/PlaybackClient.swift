import Dependencies
import DependenciesMacros
import Foundation

#if canImport(MusicKit)
  import MusicKit
#endif

#if os(iOS)
  import AVFoundation
  import Darwin
#endif

enum PlaybackEvent: Equatable, Sendable {
  case playStatusChanged(PlaybackFeature.PlayStatus)
  case currentItemChanged(ApprovedTrack.ID)
  case progressChanged(PlaybackProgress)
}

@DependencyClient
struct PlaybackClient: Sendable {
  var playTrack: @Sendable (_ item: PlaybackItem) async throws -> Void
  var playTracksInOrder: @Sendable (_ items: [PlaybackItem]) async throws -> Void
  var pause: @Sendable () async -> Void
  var resume: @Sendable () async throws -> Void
  var seek: @Sendable (_ time: TimeInterval) async -> Void
  var skipToNext: @Sendable () async throws -> Void
  var skipToPrevious: @Sendable () async throws -> Void
  var stop: @Sendable () async -> Void
  var events: @Sendable () -> AsyncStream<PlaybackEvent> = { AsyncStream { $0.finish() } }
}

extension PlaybackClient: DependencyKey {
  #if os(iOS) && targetEnvironment(simulator)
    static let liveValue = Self.simulator
  #elseif canImport(MusicKit)
    static let liveValue = Self.live
  #else
    static let liveValue = Self.noop
  #endif

  static let testValue = Self.noop
}

extension DependencyValues {
  var playback: PlaybackClient {
    get { self[PlaybackClient.self] }
    set { self[PlaybackClient.self] = newValue }
  }
}

extension PlaybackClient {
  #if canImport(MusicKit)
    static let live = Self(
      playTrack: { item in
        try await Self.play(items: [item], repeats: false)
      },
      playTracksInOrder: { items in
        try await Self.play(items: items, repeats: true)
      },
      pause: {
        await Self.pausePlayback()
      },
      resume: {
        try await Self.resumePlayback()
      },
      seek: { time in
        await Self.seekPlayback(to: time)
      },
      skipToNext: {
        try await Self.skipToNextEntry()
      },
      skipToPrevious: {
        try await Self.skipToPreviousEntry()
      },
      stop: {
        await Self.stopPlayback()
      },
      events: {
        Self.playbackEvents()
      },
    )
  #endif

  static let noop = Self(
    playTrack: { _ in },
    playTracksInOrder: { _ in },
    pause: {},
    resume: {},
    seek: { _ in },
    skipToNext: {},
    skipToPrevious: {},
    stop: {},
    events: { AsyncStream { $0.finish() } },
  )

  #if os(iOS)
    static let simulator: Self = {
      let state = SimulatorPlaybackState()
      return Self(
        playTrack: { item in
          await state.play(items: [item], repeats: false)
        },
        playTracksInOrder: { items in
          await state.play(items: items, repeats: true)
        },
        pause: {
          await state.pause()
        },
        resume: {
          await state.resume()
        },
        seek: { time in
          await state.seek(to: time)
        },
        skipToNext: {
          await state.skipToNext()
        },
        skipToPrevious: {
          await state.skipToPrevious()
        },
        stop: {
          await state.stop()
        },
        events: {
          state.events()
        },
      )
    }()
  #endif

  #if canImport(MusicKit)
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
    private static func play(
      items: [PlaybackItem],
      repeats: Bool,
    ) async throws {
      guard !items.isEmpty else { return }
      guard await self.requestAuthorization() else {
        throw PlaybackClientError.notAuthorized
      }

      #if os(iOS)
        self.activateAudioSession()
        let hidesArtwork = items.contains { !$0.allowsArtwork }
        PlaybackNowPlayingContext.shared.set(items: items, hidesArtwork: hidesArtwork)
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
      let repeatMode: MusicKit.MusicPlayer.RepeatMode = repeats ? .all : .none
      player.state.repeatMode = repeatMode
      try await player.play()

      #if os(iOS)
        if hidesArtwork {
          await self.refreshNowPlayingInfo(for: items[0], hidesArtwork: true)
        }
      #endif
    }

    private static func playbackEvents() -> AsyncStream<PlaybackEvent> {
      AsyncStream { continuation in
        let task = Task { @MainActor in
          var lastPlayStatusEvent: PlaybackEvent?
          var lastCurrentItemID: ApprovedTrack.ID?
          var lastProgress: PlaybackProgress?
          while !Task.isCancelled {
            let player = ApplicationMusicPlayer.shared
            if let event = self.playbackEvent(
              for: player.state.playbackStatus,
            ), event != lastPlayStatusEvent {
              lastPlayStatusEvent = event
              continuation.yield(event)
            }
            if let currentItemID = self.currentItemID(for: player) {
              if currentItemID != lastCurrentItemID {
                lastCurrentItemID = currentItemID
                continuation.yield(.currentItemChanged(currentItemID))
                #if os(iOS)
                  if PlaybackNowPlayingContext.shared.hidesArtwork,
                     let item = PlaybackNowPlayingContext.shared.item(for: currentItemID) {
                    await self.updateNowPlayingInfo(for: item, hidesArtwork: true)
                  }
                #endif
              }
            } else {
              lastCurrentItemID = nil
            }
            if let progress = self.playbackProgress(for: player), progress != lastProgress {
              lastProgress = progress
              continuation.yield(.progressChanged(progress))
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
          }
          continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
      }
    }

    private static func playbackEvent(
      for status: MusicKit.MusicPlayer.PlaybackStatus,
    ) -> PlaybackEvent? {
      switch status {
      case .playing, .seekingForward, .seekingBackward:
        .playStatusChanged(.playing)
      case .paused, .interrupted, .stopped:
        .playStatusChanged(.paused)
      @unknown default:
        nil
      }
    }

    @MainActor
    private static func playbackProgress(for player: ApplicationMusicPlayer) -> PlaybackProgress? {
      let elapsedTime = player.playbackTime
      guard elapsedTime.isFinite, elapsedTime >= 0 else { return nil }
      guard let duration = self.playbackDuration(for: player.queue.currentEntry),
            duration > 0 else {
        return nil
      }
      return PlaybackProgress(elapsedTime: min(elapsedTime, duration), duration: duration)
    }

    @MainActor
    private static func currentItemID(for player: ApplicationMusicPlayer) -> ApprovedTrack.ID? {
      switch player.queue.currentEntry?.item {
      case .song(let song):
        return .init(song.id.rawValue)
      case .musicVideo(let musicVideo):
        return .init(musicVideo.id.rawValue)
      case nil:
        return nil
      @unknown default:
        return nil
      }
    }

    @MainActor
    private static func playbackDuration(for entry: MusicKit.MusicPlayer.Queue
      .Entry?) -> TimeInterval? {
      guard let entry else { return nil }
      if let startTime = entry.startTime,
         let endTime = entry.endTime {
        let duration = endTime - startTime
        if duration.isFinite, duration > 0 {
          return duration
        }
      }
      switch entry.item {
      case .song(let song):
        return song.duration
      case .musicVideo(let musicVideo):
        return musicVideo.duration
      case nil:
        return nil
      @unknown default:
        return nil
      }
    }

    @MainActor
    private static func pausePlayback() async {
      ApplicationMusicPlayer.shared.pause()
    }

    @MainActor
    private static func resumePlayback() async throws {
      try await ApplicationMusicPlayer.shared.play()
    }

    @MainActor
    private static func seekPlayback(to time: TimeInterval) async {
      guard time.isFinite else { return }
      ApplicationMusicPlayer.shared.playbackTime = max(0, time)
    }

    @MainActor
    private static func skipToNextEntry() async throws {
      try await ApplicationMusicPlayer.shared.skipToNextEntry()
    }

    @MainActor
    private static func skipToPreviousEntry() async throws {
      try await ApplicationMusicPlayer.shared.skipToPreviousEntry()
    }

    @MainActor
    private static func stopPlayback() async {
      #if os(iOS)
        PlaybackNowPlayingContext.shared.clear()
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
                               let artworkURL = item.artworkURL {
          await self.artwork(for: artworkURL)
        } else {
          LoadedArtwork?.none
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
  #endif
}

#if os(iOS)
  private actor SimulatorPlaybackState {
    private let defaultDuration: TimeInterval = 180
    private var continuations: [UUID: AsyncStream<PlaybackEvent>.Continuation] = [:]
    private var currentIndex = 0
    private var duration: TimeInterval = 180
    private var elapsedTime: TimeInterval = 0
    private var items: [PlaybackItem] = []
    private var playStatus: PlaybackFeature.PlayStatus = .paused
    private var repeats = false
    private var ticker: Task<Void, Never>?

    nonisolated func events() -> AsyncStream<PlaybackEvent> {
      AsyncStream { continuation in
        let id = UUID()
        Task {
          await self.addContinuation(continuation, id: id)
        }
        continuation.onTermination = { _ in
          Task {
            await self.removeContinuation(id: id)
          }
        }
      }
    }

    func play(items: [PlaybackItem], repeats: Bool) {
      guard !items.isEmpty else {
        self.stop()
        return
      }
      self.items = items
      self.currentIndex = 0
      self.repeats = repeats
      self.duration = self.defaultDuration
      self.elapsedTime = 0
      self.playStatus = .playing
      self.sendSnapshot()
      self.startTickerIfNeeded()
    }

    func pause() {
      guard self.playStatus != .paused else { return }
      self.playStatus = .paused
      self.send(.playStatusChanged(.paused))
      self.stopTicker()
    }

    func resume() {
      guard !self.items.isEmpty else { return }
      guard self.playStatus != .playing else { return }
      if self.elapsedTime >= self.duration {
        self.elapsedTime = 0
      }
      self.playStatus = .playing
      self.send(.playStatusChanged(.playing))
      self.send(.progressChanged(self.progress))
      self.startTickerIfNeeded()
    }

    func seek(to time: TimeInterval) {
      guard time.isFinite else { return }
      self.elapsedTime = min(self.duration, max(0, time))
      self.send(.progressChanged(self.progress))
    }

    func skipToNext() {
      guard !self.items.isEmpty else { return }
      if self.currentIndex < self.items.index(before: self.items.endIndex) {
        self.currentIndex += 1
      } else if self.repeats {
        self.currentIndex = 0
      }
      self.restartCurrentItem()
    }

    func skipToPrevious() {
      guard !self.items.isEmpty else { return }
      if self.currentIndex > self.items.startIndex {
        self.currentIndex -= 1
      } else if self.repeats {
        self.currentIndex = self.items.index(before: self.items.endIndex)
      }
      self.restartCurrentItem()
    }

    func stop() {
      self.playStatus = .paused
      self.elapsedTime = 0
      self.send(.playStatusChanged(.paused))
      self.send(.progressChanged(self.progress))
      self.stopTicker()
    }

    private var currentItem: PlaybackItem? {
      guard self.items.indices.contains(self.currentIndex) else { return nil }
      return self.items[self.currentIndex]
    }

    private var progress: PlaybackProgress {
      .init(elapsedTime: self.elapsedTime, duration: self.duration)
    }

    private func addContinuation(
      _ continuation: AsyncStream<PlaybackEvent>.Continuation,
      id: UUID,
    ) {
      self.continuations[id] = continuation
      self.sendSnapshot(to: continuation)
    }

    private func removeContinuation(id: UUID) {
      self.continuations[id] = nil
    }

    private func restartCurrentItem() {
      self.duration = self.defaultDuration
      self.elapsedTime = 0
      self.sendCurrentItem()
      self.send(.progressChanged(self.progress))
      if self.playStatus == .playing {
        self.startTickerIfNeeded()
      }
    }

    private func sendSnapshot() {
      self.sendCurrentItem()
      self.send(.playStatusChanged(self.playStatus))
      self.send(.progressChanged(self.progress))
    }

    private func sendSnapshot(to continuation: AsyncStream<PlaybackEvent>.Continuation) {
      if let currentItem {
        continuation.yield(.currentItemChanged(currentItem.id))
      }
      continuation.yield(.playStatusChanged(self.playStatus))
      continuation.yield(.progressChanged(self.progress))
    }

    private func sendCurrentItem() {
      guard let currentItem else { return }
      self.send(.currentItemChanged(currentItem.id))
    }

    private func send(_ event: PlaybackEvent) {
      for continuation in self.continuations.values {
        continuation.yield(event)
      }
    }

    private func startTickerIfNeeded() {
      guard self.ticker == nil else { return }
      self.ticker = Task.detached {
        while !Task.isCancelled {
          try? await Task.sleep(nanoseconds: 250_000_000)
          await self.tick()
        }
      }
    }

    private func stopTicker() {
      self.ticker?.cancel()
      self.ticker = nil
    }

    private func tick() {
      guard self.playStatus == .playing, !self.items.isEmpty else {
        self.stopTicker()
        return
      }
      self.elapsedTime += 0.25
      if self.elapsedTime >= self.duration {
        self.finishCurrentItem()
      } else {
        self.send(.progressChanged(self.progress))
      }
    }

    private func finishCurrentItem() {
      if self.items.count > 1, self.currentIndex < self.items.index(before: self.items.endIndex) {
        self.currentIndex += 1
        self.restartCurrentItem()
      } else if self.repeats {
        self.currentIndex = 0
        self.restartCurrentItem()
      } else {
        self.elapsedTime = self.duration
        self.playStatus = .paused
        self.send(.progressChanged(self.progress))
        self.send(.playStatusChanged(.paused))
        self.stopTicker()
      }
    }
  }
#endif

#if os(iOS)
  private struct LoadedArtwork {
    let data: Data
    let mimeType: String
  }

  @MainActor
  private final class PlaybackNowPlayingContext {
    static let shared = PlaybackNowPlayingContext()

    private var itemsByID: [ApprovedTrack.ID: PlaybackItem] = [:]
    private(set) var hidesArtwork = false

    func set(items: [PlaybackItem], hidesArtwork: Bool) {
      self.hidesArtwork = hidesArtwork
      self.itemsByID = items.reduce(into: [:]) { itemsByID, item in
        itemsByID[item.id] = item
      }
    }

    func item(for id: ApprovedTrack.ID) -> PlaybackItem? {
      self.itemsByID[id]
    }

    func clear() {
      self.hidesArtwork = false
      self.itemsByID = [:]
    }
  }

  @MainActor
  private final class MediaRemotePrivateClient {
    static let shared = MediaRemotePrivateClient()

    private let handle: UnsafeMutableRawPointer?

    private init() {
      self.handle = dlopen(
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
        self.set(
          "kMRMediaRemoteNowPlayingInfoArtworkMIMEType",
          artwork.mimeType as NSString,
          in: &info,
        )
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
