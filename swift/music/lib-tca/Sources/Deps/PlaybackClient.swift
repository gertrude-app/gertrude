import Dependencies
import DependenciesMacros
import Foundation
import GertieApp

#if canImport(MusicKit)
  import Combine
  import MusicKit
#endif

#if os(iOS)
  import AVFoundation
#endif

enum PlaybackEvent: Equatable, Sendable {
  case playStatusChanged(PlaybackFeature.PlayStatus)
  case currentItemChanged(ApprovedTrack.ID)
  case progressChanged(PlaybackProgress)
}

@DependencyClient
struct PlaybackClient: Sendable {
  var playTrack: @Sendable (_ item: PlaybackItem) async throws -> Void
  var playQueue: @Sendable (_ items: [PlaybackItem], _ startIndex: Int) async throws -> Void
  var playQueueFromPosition: @Sendable (
    _ items: [PlaybackItem],
    _ startIndex: Int,
    _ position: TimeInterval,
  ) async throws -> Void
  var pause: @Sendable () async -> Void
  var restartCurrentEntry: @Sendable () async -> Void
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
        try await Self.play(items: [item], startIndex: 0, repeats: false)
      },
      playQueue: { items, startIndex in
        try await Self.play(items: items, startIndex: startIndex, repeats: true)
      },
      playQueueFromPosition: { items, startIndex, position in
        try await Self.play(
          items: items,
          startIndex: startIndex,
          repeats: items.count > 1,
          startTime: position,
        )
      },
      pause: {
        await Self.pausePlayback()
      },
      restartCurrentEntry: {
        await Self.restartPlaybackCurrentEntry()
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
    playQueue: { _, _ in },
    playQueueFromPosition: { _, _, _ in },
    pause: {},
    restartCurrentEntry: {},
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
          await state.play(items: [item], startIndex: 0, repeats: false)
        },
        playQueue: { items, startIndex in
          await state.play(items: items, startIndex: startIndex, repeats: true)
        },
        playQueueFromPosition: { items, startIndex, position in
          await state.play(
            items: items,
            startIndex: startIndex,
            repeats: items.count > 1,
            startTime: position,
          )
        },
        pause: {
          await state.pause()
        },
        restartCurrentEntry: {
          await state.restartCurrentEntry()
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
    private static func requestAuthorization() async throws {
      switch MusicAuthorization.currentStatus {
      case .authorized:
        return
      case .denied:
        throw PlaybackClientError.musicAccessDenied
      case .restricted:
        throw PlaybackClientError.musicAccessRestricted
      case .notDetermined:
        switch await MusicAuthorization.request() {
        case .authorized:
          return
        case .denied:
          throw PlaybackClientError.musicAccessDenied
        case .restricted:
          throw PlaybackClientError.musicAccessRestricted
        case .notDetermined:
          throw PlaybackClientError.musicAccessDenied
        @unknown default:
          throw PlaybackClientError.playbackFailed
        }
      @unknown default:
        throw PlaybackClientError.playbackFailed
      }
    }

    private static func ensureSubscriptionAllowsPlayback() async throws {
      do {
        let subscription = try await MusicSubscription.current
        guard subscription.canPlayCatalogContent else {
          throw PlaybackClientError.appleMusicSubscriptionRequired
        }
      } catch let error as MusicSubscription.Error {
        switch error {
        case .permissionDenied:
          throw PlaybackClientError.musicAccessDenied
        case .privacyAcknowledgementRequired:
          throw PlaybackClientError.privacyAcknowledgementRequired
        case .unknown:
          return
        @unknown default:
          return
        }
      } catch let error as PlaybackClientError {
        throw error
      } catch {
        return
      }
    }

    @MainActor
    private static func play(
      items: [PlaybackItem],
      startIndex: Int,
      repeats: Bool,
      startTime: TimeInterval? = nil,
    ) async throws {
      guard !items.isEmpty, items.indices.contains(startIndex) else { return }
      try await self.requestAuthorization()
      try await self.ensureSubscriptionAllowsPlayback()
      let songs = try await self.songs(for: items)

      #if os(iOS)
        await self.activateAudioSession()
      #endif
      let player = ApplicationMusicPlayer.shared
      player.queue = ApplicationMusicPlayer.Queue(for: songs, startingAt: songs[startIndex])
      let seekTime: TimeInterval? = if let startTime, startTime.isFinite {
        max(0, startTime)
      } else {
        nil
      }
      if let seekTime {
        player.playbackTime = seekTime
      }
      let repeatMode: MusicKit.MusicPlayer.RepeatMode = repeats ? .all : .none
      player.state.repeatMode = repeatMode
      do {
        try await player.play()
        if let seekTime {
          player.playbackTime = seekTime
        }
      } catch {
        throw PlaybackClientError.playbackFailed
      }
    }

    private static func playbackEvents() -> AsyncStream<PlaybackEvent> {
      AsyncStream { continuation in
        let stateTask = Task { @MainActor in
          let player = ApplicationMusicPlayer.shared
          var lastPlayStatusEvent: PlaybackEvent?
          @MainActor
          func yieldPlaybackStatus() {
            guard let event = Self.playbackEvent(for: player.state.playbackStatus),
                  event != lastPlayStatusEvent else { return }
            lastPlayStatusEvent = event
            continuation.yield(event)
          }
          yieldPlaybackStatus()
          for await _ in player.state.objectWillChange.values {
            await Task.yield()
            yieldPlaybackStatus()
          }
        }
        let queueTask = Task { @MainActor in
          let player = ApplicationMusicPlayer.shared
          var lastCurrentItemID: ApprovedTrack.ID?
          @MainActor
          func yieldCurrentItem() {
            if let currentItemID = Self.currentItemID(for: player) {
              guard currentItemID != lastCurrentItemID else { return }
              lastCurrentItemID = currentItemID
              continuation.yield(.currentItemChanged(currentItemID))
            } else {
              lastCurrentItemID = nil
            }
          }
          yieldCurrentItem()
          for await _ in player.queue.objectWillChange.values {
            await Task.yield()
            yieldCurrentItem()
          }
        }
        let progressTask = Task { @MainActor in
          let player = ApplicationMusicPlayer.shared
          var lastProgress: PlaybackProgress?
          while !Task.isCancelled {
            if let progress = Self.playbackProgress(for: player), progress != lastProgress {
              lastProgress = progress
              continuation.yield(.progressChanged(progress))
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
          }
        }
        continuation.onTermination = { _ in
          stateTask.cancel()
          queueTask.cancel()
          progressTask.cancel()
        }
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
      do {
        try await ApplicationMusicPlayer.shared.play()
      } catch {
        throw PlaybackClientError.playbackFailed
      }
    }

    @MainActor
    private static func seekPlayback(to time: TimeInterval) async {
      guard time.isFinite else { return }
      ApplicationMusicPlayer.shared.playbackTime = max(0, time)
    }

    @MainActor
    private static func restartPlaybackCurrentEntry() async {
      ApplicationMusicPlayer.shared.restartCurrentEntry()
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
      ApplicationMusicPlayer.shared.stop()
    }

    #if os(iOS)
      private static func activateAudioSession() async {
        await Task.detached(priority: .userInitiated) {
          let session = AVAudioSession.sharedInstance()
          try? session.setCategory(.playback, mode: .default)
          try? session.setActive(true)
        }.value
      }
    #endif

    private static func songs(for items: [PlaybackItem]) async throws -> [Song] {
      let songIds = items.map { MusicItemID($0.id.rawValue) }
      let request = MusicCatalogResourceRequest<Song>(
        matching: \.id,
        memberOf: songIds,
      )
      do {
        let response = try await request.response()
        let songsByID = Dictionary(uniqueKeysWithValues: response.items
          .map { ($0.id.rawValue, $0) })
        return try items.map { item in
          guard let song = songsByID[item.id.rawValue] else {
            throw PlaybackClientError.trackUnavailable
          }
          return song
        }
      } catch let error as MusicDataRequest.Error {
        if error.status == 404 {
          throw PlaybackClientError.trackUnavailable
        }
        throw PlaybackClientError.catalogLookupFailed
      } catch let error as PlaybackClientError {
        throw error
      } catch {
        throw PlaybackClientError.catalogLookupFailed
      }
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
    private var progressTicker: Task<Void, Never>?

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

    func play(
      items: [PlaybackItem],
      startIndex: Int,
      repeats: Bool,
      startTime: TimeInterval = 0,
    ) {
      guard !items.isEmpty else {
        self.stop()
        return
      }
      self.items = items
      self.currentIndex = items.indices.contains(startIndex) ? startIndex : 0
      self.repeats = repeats
      self.duration = self.defaultDuration
      self.elapsedTime = min(self.duration, max(0, startTime))
      self.playStatus = .playing
      self.sendCurrentState()
      self.startProgressTickerIfNeeded()
    }

    func pause() {
      guard self.playStatus != .paused else { return }
      self.playStatus = .paused
      self.send(.playStatusChanged(.paused))
      self.stopProgressTicker()
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
      self.startProgressTickerIfNeeded()
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
      self.restartCurrentEntry()
    }

    func skipToPrevious() {
      guard !self.items.isEmpty else { return }
      if self.currentIndex > self.items.startIndex {
        self.currentIndex -= 1
      } else if self.repeats {
        self.currentIndex = self.items.index(before: self.items.endIndex)
      }
      self.restartCurrentEntry()
    }

    func stop() {
      self.playStatus = .paused
      self.elapsedTime = 0
      self.send(.playStatusChanged(.paused))
      self.send(.progressChanged(self.progress))
      self.stopProgressTicker()
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
      self.sendCurrentState(to: continuation)
    }

    private func removeContinuation(id: UUID) {
      self.continuations[id] = nil
    }

    func restartCurrentEntry() {
      self.duration = self.defaultDuration
      self.elapsedTime = 0
      self.sendCurrentItem()
      self.send(.progressChanged(self.progress))
      if self.playStatus == .playing {
        self.startProgressTickerIfNeeded()
      }
    }

    private func sendCurrentState() {
      self.sendCurrentItem()
      self.send(.playStatusChanged(self.playStatus))
      self.send(.progressChanged(self.progress))
    }

    private func sendCurrentState(to continuation: AsyncStream<PlaybackEvent>.Continuation) {
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

    private func startProgressTickerIfNeeded() {
      guard self.progressTicker == nil else { return }
      self.progressTicker = Task.detached {
        while !Task.isCancelled {
          try? await Task.sleep(nanoseconds: 250_000_000)
          await self.tick()
        }
      }
    }

    private func stopProgressTicker() {
      self.progressTicker?.cancel()
      self.progressTicker = nil
    }

    private func tick() {
      guard self.playStatus == .playing, !self.items.isEmpty else {
        self.stopProgressTicker()
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
        self.restartCurrentEntry()
      } else if self.repeats {
        self.currentIndex = 0
        self.restartCurrentEntry()
      } else {
        self.elapsedTime = self.duration
        self.playStatus = .paused
        self.send(.progressChanged(self.progress))
        self.send(.playStatusChanged(.paused))
        self.stopProgressTicker()
      }
    }
  }
#endif

enum PlaybackClientError: Error, Equatable, Sendable {
  case appleMusicSubscriptionRequired
  case catalogLookupFailed
  case musicAccessDenied
  case musicAccessRestricted
  case playbackFailed
  case privacyAcknowledgementRequired
  case trackUnavailable
}
