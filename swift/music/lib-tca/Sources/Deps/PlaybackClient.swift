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
  case progressChanged(PlaybackProgress)
  case queueEnded
  case snapshotChanged(PlaybackSnapshot)
}

enum PlaybackSkipOutcome: Equatable, Sendable {
  case advanced
  case queueEnded
}

enum PlaybackObservationStatus: Equatable, Sendable {
  case interrupted
  case paused
  case playing
  case stopped
}

struct PlaybackTerminalDetector: Sendable {
  struct Observation: Equatable, Sendable {
    var isRepeatModeNone: Bool
    var snapshot: PlaybackSnapshot
    var status: PlaybackObservationStatus
  }

  private var previous: Observation?

  mutating func update(_ observation: Observation) -> Bool {
    defer { self.previous = observation }
    guard let previous = self.previous,
          previous.status == .playing,
          observation.status == .paused || observation.status == .stopped,
          observation.isRepeatModeNone,
          !previous.snapshot.entries.isEmpty,
          previous.snapshot.entries.map(\.id) == observation.snapshot.entries.map(\.id),
          previous.snapshot.currentEntryID == previous.snapshot.entries.last?.id,
          observation.snapshot.currentEntryID == observation.snapshot.entries.first?.id,
          previous.snapshot.progress.duration > 0,
          previous.snapshot.progress.fraction >= 0.9,
          observation.snapshot.progress.elapsedTime <= 0.25
    else { return false }
    return true
  }
}

@DependencyClient
struct PlaybackClient: Sendable {
  var clearQueue: @Sendable () async -> Void
  var clearUpcoming: @Sendable () async throws -> PlaybackSnapshot
  var events: @Sendable () -> AsyncStream<PlaybackEvent> = { AsyncStream { $0.finish() } }
  var insertIntoQueue: @Sendable (
    _ items: [PlaybackItem],
    _ position: PlaybackQueueInsertionPosition,
  ) async throws -> PlaybackSnapshot
  var loadAlbumIDs: @Sendable (_ songID: ApprovedTrack.ID) async throws -> [ApprovedAlbum.ID]
  var pause: @Sendable () async -> Void
  var playNow: @Sendable (_ items: [PlaybackItem], _ startIndex: Int) async throws
    -> PlaybackSnapshot
  var removeQueueEntry: @Sendable (_ entryID: PlaybackQueueEntry.ID) async throws
    -> PlaybackSnapshot
  var reorderUpcoming: @Sendable (_ entryIDs: [PlaybackQueueEntry.ID]) async throws
    -> PlaybackSnapshot
  var restartCurrentEntry: @Sendable () async -> Void
  var restoreQueue: @Sendable (_ checkpoint: PlaybackCheckpoint) async throws -> PlaybackSnapshot
  var resume: @Sendable () async throws -> Void
  var seek: @Sendable (_ time: TimeInterval) async -> Void
  var skipToNext: @Sendable () async throws -> PlaybackSkipOutcome
  var skipToPrevious: @Sendable () async throws -> Void
  var stop: @Sendable () async -> Void
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
      clearQueue: {
        await Self.clearPlaybackQueue()
      },
      clearUpcoming: {
        try await Self.clearUpcomingEntries()
      },
      events: {
        Self.playbackEvents()
      },
      insertIntoQueue: { items, position in
        try await Self.insertIntoQueue(items, position: position)
      },
      loadAlbumIDs: { songID in
        try await Self.loadAlbumIDs(for: songID)
      },
      pause: {
        await Self.pausePlayback()
      },
      playNow: { items, startIndex in
        try await Self.playNow(items: items, startIndex: startIndex)
      },
      removeQueueEntry: { entryID in
        try await Self.removeQueueEntry(entryID)
      },
      reorderUpcoming: { entryIDs in
        try await Self.reorderUpcoming(entryIDs)
      },
      restartCurrentEntry: {
        await Self.restartPlaybackCurrentEntry()
      },
      restoreQueue: { checkpoint in
        try await Self.restoreQueue(from: checkpoint)
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
    )
  #endif

  static let noop = Self(
    clearQueue: {},
    clearUpcoming: { .empty },
    events: { AsyncStream { $0.finish() } },
    insertIntoQueue: { _, _ in .empty },
    loadAlbumIDs: { _ in [] },
    pause: {},
    playNow: { _, _ in .empty },
    removeQueueEntry: { _ in .empty },
    reorderUpcoming: { _ in .empty },
    restartCurrentEntry: {},
    restoreQueue: { _ in .empty },
    resume: {},
    seek: { _ in },
    skipToNext: { .advanced },
    skipToPrevious: {},
    stop: {},
  )

  #if os(iOS)
    static let simulator = Self.simulated()
  #endif

  static func simulated(
    defaultDuration: TimeInterval = 180,
    sleep: @escaping @Sendable (Duration) async -> Void = { duration in
      try? await Task.sleep(for: duration)
    },
  ) -> Self {
    let state = SimulatorPlaybackState(
      defaultDuration: defaultDuration,
      sleep: sleep,
    )
    return Self(
      clearQueue: {
        await state.clearQueue()
      },
      clearUpcoming: {
        await state.clearUpcoming()
      },
      events: {
        state.events()
      },
      insertIntoQueue: { items, position in
        await state.insert(items, position: position)
      },
      loadAlbumIDs: { songID in
        await state.albumIDs(for: songID)
      },
      pause: {
        await state.pause()
      },
      playNow: { items, startIndex in
        await state.playNow(items: items, startIndex: startIndex)
      },
      removeQueueEntry: { entryID in
        await state.remove(entryID: entryID)
      },
      reorderUpcoming: { entryIDs in
        await state.reorderUpcoming(entryIDs: entryIDs)
      },
      restartCurrentEntry: {
        await state.restartCurrentEntry()
      },
      restoreQueue: { checkpoint in
        await state.restore(checkpoint)
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
    )
  }

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
          throw PlaybackClientError
            .playbackFailed(.init(summary: "unknown authorization request status"))
        }
      @unknown default:
        throw PlaybackClientError.playbackFailed(.init(summary: "unknown authorization status"))
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
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        return
      }
    }

    @MainActor
    private static func playNow(
      items: [PlaybackItem],
      startIndex: Int,
    ) async throws -> PlaybackSnapshot {
      guard items.indices.contains(startIndex) else {
        return self.playbackSnapshot(for: ApplicationMusicPlayer.shared)
      }
      let requestedItems = Array(items[startIndex...])
      try Task.checkCancellation()
      try await self.requestAuthorization()
      try Task.checkCancellation()
      try await self.ensureSubscriptionAllowsPlayback()
      try Task.checkCancellation()
      let songs = try await self.songs(for: requestedItems)
      try Task.checkCancellation()

      #if os(iOS)
        await self.activateAudioSession()
        try Task.checkCancellation()
      #endif
      let player = ApplicationMusicPlayer.shared
      let existingEntries = Array(player.queue.entries)
      let existingUpcoming: [MusicKit.MusicPlayer.Queue.Entry] = if let currentEntryID = player
        .queue.currentEntry?.id,
        let currentIndex = existingEntries.firstIndex(where: { $0.id == currentEntryID }) {
        Array(existingEntries.dropFirst(currentIndex + 1))
      } else {
        []
      }
      let requestedEntries = songs.map { MusicKit.MusicPlayer.Queue.Entry($0) }
      let entries = requestedEntries + existingUpcoming
      guard let firstEntry = entries.first else {
        return self.playbackSnapshot(for: player)
      }
      let expectedEntryCount = entries.count
      try Task.checkCancellation()
      player.stop()
      try Task.checkCancellation()
      player.queue = ApplicationMusicPlayer.Queue(entries, startingAt: firstEntry)
      try Task.checkCancellation()
      player.state.repeatMode = MusicKit.MusicPlayer.RepeatMode.none
      try Task.checkCancellation()
      do {
        try await ApplicationMusicPlayer.shared.play()
        try Task.checkCancellation()
        for _ in 0 ..< 30 {
          guard ApplicationMusicPlayer.shared.queue.entries.count < expectedEntryCount
            || ApplicationMusicPlayer.shared.queue.currentEntry == nil else { break }
          try await Task.sleep(nanoseconds: 100_000_000)
          try Task.checkCancellation()
        }
        return self.playbackSnapshot(for: ApplicationMusicPlayer.shared)
      } catch is CancellationError {
        throw CancellationError()
      } catch let error as MusicTokenRequestError {
        throw PlaybackClientError.tokenRequest(error, fallback: PlaybackClientError.playbackFailed)
      } catch {
        throw PlaybackClientError.playbackFailed(.init(unexpected: error))
      }
    }

    private static func loadAlbumIDs(
      for songID: ApprovedTrack.ID,
    ) async throws -> [ApprovedAlbum.ID] {
      let request = MusicCatalogResourceRequest<Song>(
        matching: \.id,
        memberOf: [MusicItemID(songID.rawValue)],
      )
      do {
        guard let song = try await request.response().items.first else {
          throw PlaybackClientError.trackUnavailable
        }
        let detailedSong = try await song.with(.albums)
        return detailedSong.albums?.map { ApprovedAlbum.ID($0.id.rawValue) } ?? []
      } catch let error as MusicDataRequest.Error {
        if error.status == 404 {
          throw PlaybackClientError.trackUnavailable
        }
        throw PlaybackClientError.catalogLookupFailed(.init(error))
      } catch let error as MusicTokenRequestError {
        throw PlaybackClientError.tokenRequest(
          error,
          fallback: PlaybackClientError.catalogLookupFailed,
        )
      } catch let error as PlaybackClientError {
        throw error
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        throw PlaybackClientError.catalogLookupFailed(.init(unexpected: error))
      }
    }

    @MainActor
    private static func insertIntoQueue(
      _ items: [PlaybackItem],
      position: PlaybackQueueInsertionPosition,
    ) async throws -> PlaybackSnapshot {
      guard !items.isEmpty else {
        return self.playbackSnapshot(for: ApplicationMusicPlayer.shared)
      }
      let player = ApplicationMusicPlayer.shared
      guard player.queue.currentEntry != nil else {
        return try await self.playNow(items: items, startIndex: 0)
      }

      try Task.checkCancellation()
      try await self.requestAuthorization()
      try Task.checkCancellation()
      try await self.ensureSubscriptionAllowsPlayback()
      try Task.checkCancellation()
      let songs = try await self.songs(for: items)
      try Task.checkCancellation()
      let insertionPosition: MusicKit.MusicPlayer.Queue.EntryInsertionPosition = switch position {
      case .next:
        .afterCurrentEntry
      case .tail:
        .tail
      }
      do {
        try await player.queue.insert(songs, position: insertionPosition)
        try Task.checkCancellation()
        return self.playbackSnapshot(for: player)
      } catch is CancellationError {
        throw CancellationError()
      } catch let error as MusicTokenRequestError {
        throw PlaybackClientError.tokenRequest(error, fallback: PlaybackClientError.playbackFailed)
      } catch {
        throw PlaybackClientError.playbackFailed(.init(unexpected: error))
      }
    }

    @MainActor
    private static func removeQueueEntry(
      _ entryID: PlaybackQueueEntry.ID,
    ) async throws -> PlaybackSnapshot {
      try Task.checkCancellation()
      let player = ApplicationMusicPlayer.shared
      guard let currentEntryID = player.queue.currentEntry?.id else {
        return self.playbackSnapshot(for: player)
      }
      var entries = player.queue.entries
      guard let currentIndex = entries.firstIndex(where: { $0.id == currentEntryID }),
            let removalIndex = entries.firstIndex(where: { $0.id == entryID }),
            removalIndex > currentIndex else {
        return self.playbackSnapshot(for: player)
      }
      entries.remove(at: removalIndex)
      try Task.checkCancellation()
      player.queue.entries = entries
      return self.playbackSnapshot(for: player)
    }

    @MainActor
    private static func reorderUpcoming(
      _ entryIDs: [PlaybackQueueEntry.ID],
    ) async throws -> PlaybackSnapshot {
      try Task.checkCancellation()
      let player = ApplicationMusicPlayer.shared
      let entries = Array(player.queue.entries)
      guard let currentEntryID = player.queue.currentEntry?.id,
            let currentIndex = entries.firstIndex(where: { $0.id == currentEntryID }) else {
        return self.playbackSnapshot(for: player)
      }
      let upcoming = Array(entries.dropFirst(currentIndex + 1))
      guard entryIDs.count == upcoming.count,
            Set(entryIDs) == Set(upcoming.map(\.id)) else {
        return self.playbackSnapshot(for: player)
      }
      let upcomingByID = Dictionary(uniqueKeysWithValues: upcoming.map { ($0.id, $0) })
      var reordered = ApplicationMusicPlayer.Queue.Entries()
      reordered.append(contentsOf: entries.prefix(currentIndex + 1))
      reordered.append(contentsOf: entryIDs.compactMap { upcomingByID[$0] })
      try Task.checkCancellation()
      player.queue.entries = reordered
      return self.playbackSnapshot(for: player)
    }

    @MainActor
    private static func restoreQueue(
      from checkpoint: PlaybackCheckpoint,
    ) async throws -> PlaybackSnapshot {
      let checkpoint = checkpoint.activeQueue
      let player = ApplicationMusicPlayer.shared
      guard checkpoint.isValid else { return self.playbackSnapshot(for: player) }
      if !player.queue.entries.isEmpty, player.queue.currentEntry != nil {
        return self.playbackSnapshot(for: player)
      }

      try Task.checkCancellation()
      try await self.requestAuthorization()
      try Task.checkCancellation()
      try await self.ensureSubscriptionAllowsPlayback()
      try Task.checkCancellation()
      let restoredQueue = try await self.restoredQueue(from: checkpoint)
      let songs = restoredQueue.songs
      try Task.checkCancellation()

      #if os(iOS)
        await self.activateAudioSession()
        try Task.checkCancellation()
      #endif
      player.stop()
      player.queue = ApplicationMusicPlayer.Queue(
        for: songs,
        startingAt: songs[restoredQueue.currentIndex],
      )
      player.state.repeatMode = MusicKit.MusicPlayer.RepeatMode.none
      do {
        try await player.prepareToPlay()
        try Task.checkCancellation()
        for _ in 0 ..< 30 {
          guard player.queue.entries.count < songs.count
            || player.queue.currentEntry == nil else { break }
          try await Task.sleep(nanoseconds: 100_000_000)
        }
        guard player.queue.entries.count == songs.count,
              player.queue.currentEntry != nil else {
          throw PlaybackClientError.playbackFailed(.init(summary: "checkpoint queue incomplete"))
        }
        player.pause()
        player.playbackTime = restoredQueue.currentItemWasAvailable
          ? checkpoint.elapsedTime : 0
        return self.playbackSnapshot(for: player)
      } catch is CancellationError {
        throw CancellationError()
      } catch let error as PlaybackClientError {
        throw error
      } catch let error as MusicTokenRequestError {
        throw PlaybackClientError.tokenRequest(error, fallback: PlaybackClientError.playbackFailed)
      } catch {
        throw PlaybackClientError.playbackFailed(.init(unexpected: error))
      }
    }

    private static func playbackEvents() -> AsyncStream<PlaybackEvent> {
      AsyncStream { continuation in
        let task = Task { @MainActor in
          let player = ApplicationMusicPlayer.shared
          var detector = PlaybackTerminalDetector()
          var lastSnapshot: PlaybackSnapshot?
          while !Task.isCancelled {
            let snapshot = Self.playbackSnapshot(for: player)
            let observation = PlaybackTerminalDetector.Observation(
              isRepeatModeNone: player.state.repeatMode == MusicKit.MusicPlayer.RepeatMode.none,
              snapshot: snapshot,
              status: Self.observationStatus(for: player.state.playbackStatus),
            )
            if detector.update(observation) {
              Self.clearPlaybackQueue()
              lastSnapshot = .empty
              continuation.yield(.queueEnded)
            } else if snapshot != lastSnapshot {
              let previousSnapshot = lastSnapshot
              lastSnapshot = snapshot
              if let previousSnapshot,
                 snapshot.hasSameSession(as: previousSnapshot) {
                continuation.yield(.progressChanged(snapshot.progress))
              } else {
                continuation.yield(.snapshotChanged(snapshot))
              }
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
          }
        }
        continuation.onTermination = { _ in
          task.cancel()
        }
      }
    }

    @MainActor
    private static func playbackSnapshot(
      for player: ApplicationMusicPlayer,
    ) -> PlaybackSnapshot {
      PlaybackSnapshot(
        entries: player.queue.entries.compactMap { entry in
          self.playbackQueueEntry(for: entry)
        },
        currentEntryID: player.queue.currentEntry?.id,
        playStatus: self.playStatus(for: player.state.playbackStatus),
        progress: self.playbackProgress(for: player),
      )
    }

    private static func observationStatus(
      for status: MusicKit.MusicPlayer.PlaybackStatus,
    ) -> PlaybackObservationStatus {
      switch status {
      case .playing, .seekingForward, .seekingBackward:
        .playing
      case .paused:
        .paused
      case .interrupted:
        .interrupted
      case .stopped:
        .stopped
      @unknown default:
        .stopped
      }
    }

    private static func playStatus(
      for status: MusicKit.MusicPlayer.PlaybackStatus,
    ) -> PlaybackFeature.PlayStatus {
      switch self.observationStatus(for: status) {
      case .playing:
        .playing
      case .interrupted, .paused, .stopped:
        .paused
      }
    }

    @MainActor
    private static func playbackProgress(for player: ApplicationMusicPlayer) -> PlaybackProgress {
      let elapsedTime = player.playbackTime
      guard elapsedTime.isFinite, elapsedTime >= 0,
            let duration = self.playbackDuration(for: player.queue.currentEntry),
            duration > 0 else { return .zero }
      return PlaybackProgress(elapsedTime: min(elapsedTime, duration), duration: duration)
    }

    @MainActor
    private static func playbackQueueEntry(
      for entry: MusicKit.MusicPlayer.Queue.Entry,
    ) -> PlaybackQueueEntry? {
      let item: PlaybackItem
      switch entry.item {
      case .song(let song):
        item = PlaybackItem(
          id: .init(song.id.rawValue),
          title: entry.title,
          artistName: entry.subtitle ?? song.artistName,
          artworkURL: (entry.artwork ?? song.artwork)?.url(width: 600, height: 600),
          albumTitle: song.albumTitle,
          duration: self.playbackDuration(for: entry),
        )
      case .musicVideo(let musicVideo):
        item = PlaybackItem(
          id: .init(musicVideo.id.rawValue),
          title: entry.title,
          artistName: entry.subtitle ?? musicVideo.artistName,
          artworkURL: (entry.artwork ?? musicVideo.artwork)?.url(width: 600, height: 600),
          duration: self.playbackDuration(for: entry),
        )
      case nil:
        return nil
      @unknown default:
        return nil
      }
      return PlaybackQueueEntry(id: entry.id, item: item)
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
    private static func clearUpcomingEntries() async throws -> PlaybackSnapshot {
      try Task.checkCancellation()
      let player = ApplicationMusicPlayer.shared
      var entries = player.queue.entries
      guard let currentEntryID = player.queue.currentEntry?.id,
            let currentIndex = entries.firstIndex(where: { $0.id == currentEntryID }) else {
        return self.playbackSnapshot(for: player)
      }
      if currentIndex < entries.index(before: entries.endIndex) {
        entries.removeSubrange(entries.index(after: currentIndex)...)
        try Task.checkCancellation()
        player.queue.entries = entries
      }
      let repeatMode: MusicKit.MusicPlayer.RepeatMode = .none
      player.state.repeatMode = repeatMode
      return self.playbackSnapshot(for: player)
    }

    @MainActor
    private static func clearPlaybackQueue() {
      let player = ApplicationMusicPlayer.shared
      player.stop()
      var entries = player.queue.entries
      entries.removeAll()
      player.queue.entries = entries
      player.state.repeatMode = MusicKit.MusicPlayer.RepeatMode.none
    }

    @MainActor
    private static func pausePlayback() async {
      ApplicationMusicPlayer.shared.pause()
    }

    @MainActor
    private static func resumePlayback() async throws {
      do {
        try await ApplicationMusicPlayer.shared.play()
      } catch let error as MusicTokenRequestError {
        throw PlaybackClientError.tokenRequest(error, fallback: PlaybackClientError.playbackFailed)
      } catch {
        throw PlaybackClientError.playbackFailed(.init(unexpected: error))
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
    private static func skipToNextEntry() async throws -> PlaybackSkipOutcome {
      let player = ApplicationMusicPlayer.shared
      let entries = Array(player.queue.entries)
      guard let currentEntryID = player.queue.currentEntry?.id else { return .advanced }
      let reachesQueueEnd = currentEntryID == entries.last?.id
      try await player.skipToNextEntry()
      guard reachesQueueEnd else { return .advanced }
      self.clearPlaybackQueue()
      return .queueEnded
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

    private struct RestoredQueue {
      var songs: [Song]
      var currentIndex: Int
      var currentItemWasAvailable: Bool
    }

    private static func restoredQueue(
      from checkpoint: PlaybackCheckpoint,
    ) async throws -> RestoredQueue {
      let songIDs = checkpoint.songIDs.map { MusicItemID($0.rawValue) }
      let request = MusicCatalogResourceRequest<Song>(
        matching: \.id,
        memberOf: songIDs,
      )
      do {
        let response = try await request.response()
        let songsByID = Dictionary(uniqueKeysWithValues: response.items.map {
          ($0.id.rawValue, $0)
        })
        let availableSongs: [(originalIndex: Int, song: Song)] = checkpoint.songIDs
          .enumerated()
          .compactMap { index, songID in
            songsByID[songID.rawValue].map { (index, $0) }
          }
        guard !availableSongs.isEmpty else {
          throw PlaybackClientError.trackUnavailable
        }
        let exactCurrentIndex = availableSongs.firstIndex {
          $0.originalIndex == checkpoint.currentIndex
        }
        let currentIndex = exactCurrentIndex
          ?? availableSongs.firstIndex(where: { $0.originalIndex > checkpoint.currentIndex })
          ?? availableSongs.index(before: availableSongs.endIndex)
        return RestoredQueue(
          songs: availableSongs.map(\.song),
          currentIndex: currentIndex,
          currentItemWasAvailable: exactCurrentIndex != nil,
        )
      } catch let error as MusicDataRequest.Error {
        if error.status == 404 {
          throw PlaybackClientError.trackUnavailable
        }
        throw PlaybackClientError.catalogLookupFailed(.init(error))
      } catch let error as MusicTokenRequestError {
        throw PlaybackClientError.tokenRequest(
          error,
          fallback: PlaybackClientError.catalogLookupFailed,
        )
      } catch let error as PlaybackClientError {
        throw error
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        throw PlaybackClientError.catalogLookupFailed(.init(unexpected: error))
      }
    }

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
        throw PlaybackClientError.catalogLookupFailed(.init(error))
      } catch let error as MusicTokenRequestError {
        throw PlaybackClientError.tokenRequest(
          error,
          fallback: PlaybackClientError.catalogLookupFailed,
        )
      } catch let error as PlaybackClientError {
        throw error
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        throw PlaybackClientError.catalogLookupFailed(.init(unexpected: error))
      }
    }
  #endif
}

private actor SimulatorPlaybackState {
  private let defaultDuration: TimeInterval
  private let sleep: @Sendable (Duration) async -> Void
  private var continuations: [UUID: AsyncStream<PlaybackEvent>.Continuation] = [:]
  private var currentIndex = 0
  private var duration: TimeInterval
  private var elapsedTime: TimeInterval = 0
  private var entryIDs: [PlaybackQueueEntry.ID] = []
  private var items: [PlaybackItem] = []
  private var nextEntryID = 0
  private var playStatus: PlaybackFeature.PlayStatus = .paused
  private var progressTicker: Task<Void, Never>?
  private var queueGeneration = 0

  init(
    defaultDuration: TimeInterval,
    sleep: @escaping @Sendable (Duration) async -> Void,
  ) {
    self.defaultDuration = defaultDuration
    self.duration = defaultDuration
    self.sleep = sleep
  }

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

  func playNow(
    items: [PlaybackItem],
    startIndex: Int,
  ) -> PlaybackSnapshot {
    guard items.indices.contains(startIndex) else { return self.snapshot }
    let requestedItems = Array(items[startIndex...])
    let upcomingStartIndex = self.items.indices.contains(self.currentIndex)
      ? self.currentIndex + 1
      : self.items.endIndex
    let existingUpcomingItems = Array(self.items.dropFirst(upcomingStartIndex))
    let existingUpcomingEntryIDs = Array(self.entryIDs.dropFirst(upcomingStartIndex))
    self.queueGeneration += 1
    self.nextEntryID = 0
    self.items = requestedItems + existingUpcomingItems
    self.entryIDs = requestedItems.map { _ in self.makeEntryID() } + existingUpcomingEntryIDs
    self.currentIndex = 0
    self.duration = self.currentItemDuration
    self.elapsedTime = 0
    self.playStatus = .playing
    self.sendSnapshot()
    self.startProgressTickerIfNeeded()
    return self.snapshot
  }

  func restore(_ checkpoint: PlaybackCheckpoint) -> PlaybackSnapshot {
    let checkpoint = checkpoint.activeQueue
    guard checkpoint.isValid, self.items.isEmpty else { return self.snapshot }
    let sourceAlbumIDs = checkpoint.sourceAlbumIDs
    self.items = checkpoint.songIDs.enumerated().map { index, songID in
      PlaybackItem(
        id: songID,
        title: "Track \(songID.rawValue)",
        artistName: "Apple Music",
        artworkURL: nil,
        albumID: sourceAlbumIDs[songID],
        duration: checkpoint.durationFallback,
        playlistSource: checkpoint.playlistSourceHints[index],
      )
    }
    self.currentIndex = checkpoint.currentIndex
    self.duration = checkpoint.durationFallback ?? self.defaultDuration
    self.elapsedTime = min(self.duration, checkpoint.elapsedTime)
    self.playStatus = .paused
    self.queueGeneration += 1
    self.nextEntryID = 0
    self.entryIDs = self.items.map { _ in self.makeEntryID() }
    self.sendSnapshot()
    return self.snapshot
  }

  func albumIDs(for songID: ApprovedTrack.ID) -> [ApprovedAlbum.ID] {
    var seenAlbumIDs = Set<ApprovedAlbum.ID>()
    return self.items.compactMap { item in
      guard item.id == songID,
            let albumID = item.albumID,
            seenAlbumIDs.insert(albumID).inserted else { return nil }
      return albumID
    }
  }

  func insert(
    _ items: [PlaybackItem],
    position: PlaybackQueueInsertionPosition,
  ) -> PlaybackSnapshot {
    guard !items.isEmpty else { return self.snapshot }
    guard !self.items.isEmpty else {
      return self.playNow(items: items, startIndex: 0)
    }
    let insertionIndex = switch position {
    case .next:
      self.currentIndex + 1
    case .tail:
      self.items.endIndex
    }
    self.items.insert(contentsOf: items, at: insertionIndex)
    self.entryIDs.insert(
      contentsOf: items.map { _ in self.makeEntryID() },
      at: insertionIndex,
    )
    self.sendSnapshot()
    return self.snapshot
  }

  func remove(entryID: PlaybackQueueEntry.ID) -> PlaybackSnapshot {
    guard let index = self.entryIDs.firstIndex(of: entryID),
          index > self.currentIndex else { return self.snapshot }
    self.items.remove(at: index)
    self.entryIDs.remove(at: index)
    self.sendSnapshot()
    return self.snapshot
  }

  func reorderUpcoming(
    entryIDs: [PlaybackQueueEntry.ID],
  ) -> PlaybackSnapshot {
    let upcomingStartIndex = self.currentIndex + 1
    let upcomingIDs = Array(self.entryIDs.dropFirst(upcomingStartIndex))
    guard entryIDs.count == upcomingIDs.count,
          Set(entryIDs) == Set(upcomingIDs) else { return self.snapshot }
    let itemsByID = Dictionary(
      uniqueKeysWithValues: zip(self.entryIDs, self.items).map { ($0, $1) },
    )
    self.entryIDs.replaceSubrange(upcomingStartIndex..., with: entryIDs)
    self.items.replaceSubrange(
      upcomingStartIndex...,
      with: entryIDs.compactMap { itemsByID[$0] },
    )
    self.sendSnapshot()
    return self.snapshot
  }

  func clearUpcoming() -> PlaybackSnapshot {
    let upcomingStartIndex = self.currentIndex + 1
    if self.items.indices.contains(self.currentIndex), upcomingStartIndex < self.items.endIndex {
      self.entryIDs.removeSubrange(upcomingStartIndex...)
      self.items.removeSubrange(upcomingStartIndex...)
    }
    self.sendSnapshot()
    return self.snapshot
  }

  func clearQueue() {
    self.entryIDs.removeAll()
    self.items.removeAll()
    self.currentIndex = 0
    self.duration = self.defaultDuration
    self.elapsedTime = 0
    self.playStatus = .paused
    self.sendSnapshot()
    self.stopProgressTicker()
  }

  func pause() {
    guard self.playStatus != .paused else { return }
    self.playStatus = .paused
    self.sendSnapshot()
    self.stopProgressTicker()
  }

  func resume() {
    guard !self.items.isEmpty else { return }
    guard self.playStatus != .playing else { return }
    if self.elapsedTime >= self.duration {
      self.elapsedTime = 0
    }
    self.playStatus = .playing
    self.sendSnapshot()
    self.startProgressTickerIfNeeded()
  }

  func seek(to time: TimeInterval) {
    guard time.isFinite else { return }
    self.elapsedTime = min(self.duration, max(0, time))
    self.sendProgress()
  }

  func skipToNext() -> PlaybackSkipOutcome {
    guard !self.items.isEmpty else { return .advanced }
    guard self.currentIndex < self.items.index(before: self.items.endIndex) else {
      self.endQueue(sendEvent: false)
      return .queueEnded
    }
    self.currentIndex += 1
    self.restartCurrentEntry()
    return .advanced
  }

  func skipToPrevious() {
    guard !self.items.isEmpty else { return }
    if self.currentIndex > self.items.startIndex {
      self.currentIndex -= 1
    }
    self.restartCurrentEntry()
  }

  func stop() {
    self.playStatus = .paused
    self.sendSnapshot()
    self.stopProgressTicker()
  }

  private var currentEntryID: PlaybackQueueEntry.ID? {
    guard self.entryIDs.indices.contains(self.currentIndex) else { return nil }
    return self.entryIDs[self.currentIndex]
  }

  private var progress: PlaybackProgress {
    guard !self.items.isEmpty else { return .zero }
    return .init(elapsedTime: self.elapsedTime, duration: self.duration)
  }

  private var snapshot: PlaybackSnapshot {
    PlaybackSnapshot(
      entries: zip(self.entryIDs, self.items).map { entryID, item in
        PlaybackQueueEntry(id: entryID, item: item)
      },
      currentEntryID: self.currentEntryID,
      playStatus: self.playStatus,
      progress: self.progress,
    )
  }

  private func addContinuation(
    _ continuation: AsyncStream<PlaybackEvent>.Continuation,
    id: UUID,
  ) {
    self.continuations[id] = continuation
    self.sendSnapshot(to: continuation)
  }

  private func makeEntryID() -> PlaybackQueueEntry.ID {
    defer { self.nextEntryID += 1 }
    return "simulator:\(self.queueGeneration):\(self.nextEntryID)"
  }

  private func removeContinuation(id: UUID) {
    self.continuations[id] = nil
  }

  func restartCurrentEntry() {
    self.duration = self.currentItemDuration
    self.elapsedTime = 0
    self.sendSnapshot()
    if self.playStatus == .playing {
      self.startProgressTickerIfNeeded()
    }
  }

  private func sendSnapshot() {
    for continuation in self.continuations.values {
      self.sendSnapshot(to: continuation)
    }
  }

  private func sendSnapshot(to continuation: AsyncStream<PlaybackEvent>.Continuation) {
    continuation.yield(.snapshotChanged(self.snapshot))
  }

  private func sendProgress() {
    for continuation in self.continuations.values {
      continuation.yield(.progressChanged(self.progress))
    }
  }

  private func startProgressTickerIfNeeded() {
    guard self.progressTicker == nil else { return }
    self.progressTicker = Task.detached {
      while !Task.isCancelled {
        await self.sleep(.milliseconds(250))
        guard !Task.isCancelled else { return }
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
      self.sendProgress()
    }
  }

  private var currentItemDuration: TimeInterval {
    guard self.items.indices.contains(self.currentIndex),
          let duration = self.items[self.currentIndex].duration,
          duration.isFinite,
          duration > 0 else { return self.defaultDuration }
    return duration
  }

  private func endQueue(sendEvent: Bool) {
    self.entryIDs.removeAll()
    self.items.removeAll()
    self.currentIndex = 0
    self.duration = self.defaultDuration
    self.elapsedTime = 0
    self.playStatus = .paused
    if sendEvent {
      for continuation in self.continuations.values {
        continuation.yield(.queueEnded)
      }
    } else {
      self.sendSnapshot()
    }
    self.stopProgressTicker()
  }

  private func finishCurrentItem() {
    if self.items.count > 1, self.currentIndex < self.items.index(before: self.items.endIndex) {
      self.currentIndex += 1
      self.restartCurrentEntry()
    } else {
      self.endQueue(sendEvent: true)
    }
  }
}

enum PlaybackClientError: Error, Equatable, Sendable {
  case appleMusicSignInRequired(PlaybackDiagnostic?)
  case appleMusicSubscriptionRequired
  case catalogLookupFailed(PlaybackDiagnostic?)
  case musicAccessDenied
  case musicAccessRestricted
  case playbackFailed(PlaybackDiagnostic?)
  case privacyAcknowledgementRequired
  case trackUnavailable

  var diagnostic: PlaybackDiagnostic? {
    switch self {
    case .appleMusicSignInRequired(let diagnostic),
         .catalogLookupFailed(let diagnostic),
         .playbackFailed(let diagnostic):
      diagnostic
    case .appleMusicSubscriptionRequired,
         .musicAccessDenied,
         .musicAccessRestricted,
         .privacyAcknowledgementRequired,
         .trackUnavailable:
      nil
    }
  }
}

struct PlaybackDiagnostic: Equatable, Sendable {
  var status: Int?
  var code: Int?
  var summary: String?

  var logDetail: String {
    var parts: [String] = []
    if let status = self.status { parts.append("status=\(status)") }
    if let code = self.code { parts.append("code=\(code)") }
    if let summary = self.summary, !summary.isEmpty { parts.append(summary) }
    return parts.joined(separator: " ")
  }
}

#if canImport(MusicKit)
  extension PlaybackDiagnostic {
    init(_ error: MusicDataRequest.Error) {
      self.init(
        status: error.status,
        code: error.code,
        summary: [error.title, error.detailText]
          .compactMap(\.self)
          .filter { !$0.isEmpty }
          .joined(separator: ": "),
      )
    }

    init(unexpected error: any Error) {
      self.init(
        status: nil,
        code: nil,
        summary: "\(type(of: error)): \(error.localizedDescription)",
      )
    }
  }

  extension PlaybackClientError {
    static func tokenRequest(
      _ error: MusicTokenRequestError,
      fallback: (PlaybackDiagnostic?) -> PlaybackClientError,
    ) -> PlaybackClientError {
      switch error {
      case .permissionDenied:
        .musicAccessDenied
      case .privacyAcknowledgementRequired:
        .privacyAcknowledgementRequired
      case .userNotSignedIn:
        .appleMusicSignInRequired(.init(summary: "tokenRequest.userNotSignedIn"))
      case .userTokenRevoked:
        .appleMusicSignInRequired(.init(summary: "tokenRequest.userTokenRevoked"))
      case .developerTokenRequestFailed:
        fallback(.init(summary: "tokenRequest.developerTokenRequestFailed"))
      case .userTokenRequestFailed:
        fallback(.init(summary: "tokenRequest.userTokenRequestFailed"))
      case .unknown:
        fallback(.init(summary: "tokenRequest.unknown"))
      @unknown default:
        fallback(.init(summary: "tokenRequest.unrecognized"))
      }
    }
  }
#endif
