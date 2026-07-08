import ComposableArchitecture
import Foundation
import GertieApp

struct PlaybackProgress: Codable, Equatable, Sendable {
  var elapsedTime: TimeInterval
  var duration: TimeInterval

  init(
    elapsedTime: TimeInterval = 0,
    duration: TimeInterval = 0,
  ) {
    self.elapsedTime = elapsedTime.isFinite ? max(0, elapsedTime) : 0
    self.duration = duration.isFinite ? max(0, duration) : 0
  }

  static let zero = Self()

  var fraction: Double {
    guard self.duration > 0 else { return 0 }
    return min(1, max(0, self.elapsedTime / self.duration))
  }
}

enum PlaybackFailure: Equatable, Sendable {
  case appleMusicSubscriptionRequired
  case catalogLookupFailed
  case musicAccessDenied
  case musicAccessRestricted
  case playbackFailed
  case privacyAcknowledgementRequired
  case trackUnavailable

  init(error: any Error) {
    switch error as? PlaybackClientError {
    case .appleMusicSubscriptionRequired:
      self = .appleMusicSubscriptionRequired
    case .catalogLookupFailed:
      self = .catalogLookupFailed
    case .musicAccessDenied:
      self = .musicAccessDenied
    case .musicAccessRestricted:
      self = .musicAccessRestricted
    case .playbackFailed:
      self = .playbackFailed
    case .privacyAcknowledgementRequired:
      self = .privacyAcknowledgementRequired
    case .trackUnavailable:
      self = .trackUnavailable
    case nil:
      self = .playbackFailed
    }
  }

  var opensSettings: Bool {
    switch self {
    case .musicAccessDenied, .musicAccessRestricted:
      true
    case .appleMusicSubscriptionRequired,
         .catalogLookupFailed,
         .playbackFailed,
         .privacyAcknowledgementRequired,
         .trackUnavailable:
      false
    }
  }
}

@Reducer
struct PlaybackFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var session: Session?
    var failure: PlaybackFailure?
    var lastCachedProgressBucket: Int?
    var requiresPlayerRestore = false
  }

  struct AlbumQueue: Equatable, Sendable {
    var items: [PlaybackItem]
    var currentIndex: Int

    init(
      items: [PlaybackItem],
      currentIndex: Int = 0,
    ) {
      self.items = items
      self.currentIndex = items.indices.contains(currentIndex) ? currentIndex : 0
    }

    var currentItem: PlaybackItem {
      self.items[self.currentIndex]
    }

    var upcomingItems: [PlaybackItem] {
      guard !self.items.isEmpty else { return [] }
      let nextIndex = self.items.index(after: self.currentIndex)
      return Array(self.items[nextIndex...]) + Array(self.items[..<self.currentIndex])
    }

    mutating func moveToItem(id: ApprovedTrack.ID) -> Bool {
      guard let index = self.items.firstIndex(where: { $0.id == id }) else {
        return false
      }
      return self.moveToIndex(index)
    }

    private mutating func moveToIndex(_ index: Int) -> Bool {
      guard self.items.indices.contains(index) else { return false }
      guard self.currentIndex != index else { return false }
      self.currentIndex = index
      return true
    }
  }

  struct Session: Equatable, Sendable {
    var playStatus: PlayStatus
    var albumQueue: AlbumQueue
    var progress: PlaybackProgress

    init(
      playStatus: PlayStatus = .playing,
      albumQueue: AlbumQueue,
      progress: PlaybackProgress = .zero,
    ) {
      precondition(!albumQueue.items.isEmpty)
      self.playStatus = playStatus
      self.albumQueue = albumQueue
      self.progress = progress
    }

    init(
      playStatus: PlayStatus = .playing,
      currentItem: PlaybackItem,
      progress: PlaybackProgress = .zero,
    ) {
      self.init(
        playStatus: playStatus,
        albumQueue: .init(items: [currentItem]),
        progress: progress,
      )
    }
  }

  enum PlayStatus: Equatable, Sendable {
    case loading
    case playing
    case paused
  }

  enum Action: Equatable {
    case cachedSessionLoaded(CachedPlaybackSession?)
    case observePlayback
    case pause
    case playAlbumQueue(items: [PlaybackItem], startIndex: Int)
    case playbackEvent(PlaybackEvent)
    case playbackFailed(PlaybackFailure)
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case playbackStarted
    case playTrack(PlaybackItem)
    case restoreCachedSession
    case resume
    case saveCachedSession
    case seek(TimeInterval)
    case skipToNext
    case skipToPrevious
    case stop
    case togglePlayPause
  }

  enum CancelID: Hashable {
    case playbackEvents
    case seek
  }

  @Dependency(\.playback) var playback
  @Dependency(\.playbackSessionCache) var playbackSessionCache
  @Dependency(\.systemSettings) var systemSettings

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .cachedSessionLoaded(let cachedSession):
        guard state.session == nil,
              let session = cachedSession?.playbackSession else { return .none }
        state.failure = nil
        state.lastCachedProgressBucket = nil
        state.requiresPlayerRestore = true
        state.session = session
        return .none

      case .observePlayback:
        return .run { send in
          for await event in self.playback.events() {
            await send(.playbackEvent(event))
          }
        }
        .cancellable(id: CancelID.playbackEvents, cancelInFlight: true)

      case .playbackEvent(.playStatusChanged(let playStatus)):
        state.setPlayStatus(playStatus)
        return self.saveCachedSession(state.session)

      case .playbackEvent(.currentItemChanged(let itemID)):
        guard state.setCurrentItem(id: itemID) else { return .none }
        return self.saveCachedSession(state.session)

      case .playbackEvent(.progressChanged(let progress)):
        state.setProgress(progress)
        guard state.shouldCacheProgressSnapshot() else { return .none }
        return self.saveCachedSession(state.session)

      case .playTrack(let item):
        state.failure = nil
        state.lastCachedProgressBucket = nil
        state.requiresPlayerRestore = false
        state.session = .init(playStatus: .loading, currentItem: item)
        return .run { send in
          do {
            try await self.playback.playTrack(item)
            await send(.playbackStarted)
          } catch {
            await send(.playbackFailed(.init(error: error)))
          }
        }

      case .playAlbumQueue(let items, let startIndex):
        guard items.indices.contains(startIndex) else { return .none }
        state.failure = nil
        state.lastCachedProgressBucket = nil
        state.requiresPlayerRestore = false
        let albumQueue = AlbumQueue(items: items, currentIndex: startIndex)
        state.session = .init(playStatus: .loading, albumQueue: albumQueue)
        return .run { send in
          do {
            try await self.playback.playAlbum(items, startIndex)
            await send(.playbackStarted)
          } catch {
            await send(.playbackFailed(.init(error: error)))
          }
        }

      case .togglePlayPause:
        switch state.session?.playStatus {
        case .playing:
          return .send(.pause)
        case .paused:
          return .send(.resume)
        case .loading, nil:
          return .none
        }

      case .pause:
        guard state.session?.playStatus == .playing else { return .none }
        state.pauseSession()
        return .merge(
          self.saveCachedSession(state.session),
          .run { _ in
            await self.playback.pause()
          },
        )

      case .restoreCachedSession:
        guard state.session == nil else { return .none }
        return .run { send in
          await send(.cachedSessionLoaded(try? self.playbackSessionCache.load()))
        }

      case .resume:
        guard let session = state.session,
              session.playStatus == .paused else { return .none }
        state.failure = nil
        if state.requiresPlayerRestore {
          state.setPlayStatus(.loading)
          return .run { send in
            do {
              try await self.playback.playAlbumFromPosition(
                session.albumQueue.items,
                session.albumQueue.currentIndex,
                session.progress.elapsedTime,
              )
              await send(.playbackStarted)
            } catch {
              await send(.playbackFailed(.init(error: error)))
            }
          }
        }
        state.resumeSession()
        return .merge(
          self.saveCachedSession(state.session),
          .run { send in
            do {
              try await self.playback.resume()
            } catch {
              await send(.playbackFailed(.init(error: error)))
            }
          },
        )

      case .saveCachedSession:
        return self.saveCachedSession(state.session)

      case .seek(let time):
        guard let duration = state.session?.progress.duration, duration > 0 else { return .none }
        let clampedTime = min(duration, max(0, time))
        state.setProgress(.init(elapsedTime: clampedTime, duration: duration))
        let seekEffect: EffectOf<Self> = .run { _ in
          await self.playback.seek(clampedTime)
        }
        .cancellable(id: CancelID.seek, cancelInFlight: true)
        return .merge(self.saveCachedSession(state.session), seekEffect)

      case .skipToNext:
        guard state.session != nil else { return .none }
        return .run { _ in
          try? await self.playback.skipToNext()
        }

      case .skipToPrevious:
        guard let elapsedTime = state.session?.progress.elapsedTime else { return .none }
        if elapsedTime > 3 {
          return .run { _ in
            await self.playback.restartCurrentEntry()
          }
        }
        return .run { _ in
          try? await self.playback.skipToPrevious()
        }

      case .stop:
        state.pauseSession()
        return .merge(
          self.saveCachedSession(state.session),
          .run { _ in
            await self.playback.stop()
          },
        )

      case .playbackStarted:
        state.failure = nil
        state.requiresPlayerRestore = false
        state.resumeSession()
        return self.saveCachedSession(state.session)

      case .playbackFailed(let failure):
        state.failure = failure
        state.pauseSession()
        log(
          failure.eventLevel,
          failure.eventDomain,
          failure.eventId,
          detail: "\(failure)",
        )
        return .none

      case .playbackFailureDismissed:
        state.failure = nil
        return .none

      case .playbackFailureActionTapped:
        guard state.failure?.opensSettings == true else { return .none }
        return .run { _ in
          await self.systemSettings.openAppSettings()
        }
      }
    }
  }

  private func saveCachedSession(_ session: PlaybackFeature.Session?) -> EffectOf<Self> {
    guard let session else { return .none }
    let cachedSession = CachedPlaybackSession(session: session)
    return .run { _ in
      try? await self.playbackSessionCache.save(cachedSession)
    }
  }
}

extension PlaybackFeature.State {
  mutating func pauseSession() {
    self.setPlayStatus(.paused)
  }

  mutating func resumeSession() {
    self.setPlayStatus(.playing)
  }

  mutating func setPlayStatus(_ playStatus: PlaybackFeature.PlayStatus) {
    guard var session = self.session else { return }
    session.playStatus = playStatus
    self.session = session
  }

  mutating func setProgress(_ progress: PlaybackProgress) {
    guard var session = self.session else { return }
    session.progress = progress
    self.session = session
  }

  mutating func setCurrentItem(id: ApprovedTrack.ID) -> Bool {
    guard var session = self.session else { return false }
    guard session.albumQueue.moveToItem(id: id) else { return false }
    session.progress = .zero
    self.lastCachedProgressBucket = nil
    self.session = session
    return true
  }

  mutating func shouldCacheProgressSnapshot() -> Bool {
    guard let elapsedTime = self.session?.progress.elapsedTime else { return false }
    let bucket = Int(elapsedTime / 5)
    guard bucket != self.lastCachedProgressBucket else { return false }
    self.lastCachedProgressBucket = bucket
    return true
  }
}

extension PlaybackFeature.Session {
  var currentItem: PlaybackItem {
    self.albumQueue.currentItem
  }

  var nextItems: [PlaybackItem] {
    self.albumQueue.upcomingItems
  }

  var isPlaying: Bool {
    self.playStatus == .playing
  }

  var isLoading: Bool {
    self.playStatus == .loading
  }

  var currentTrackID: ApprovedTrack.ID {
    self.currentItem.id
  }
}
