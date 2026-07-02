import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct PlaybackSessionCacheClient: Sendable {
  var _load: @Sendable () async throws -> CachedPlaybackSession?
  var _save: @Sendable (_ session: CachedPlaybackSession) async throws -> Void
  var _delete: @Sendable () async -> Void
}

extension PlaybackSessionCacheClient {
  func load() async throws -> CachedPlaybackSession? {
    try await self._load()
  }

  func save(_ session: CachedPlaybackSession) async throws {
    try await self._save(session)
  }

  func delete() async {
    await self._delete()
  }
}

extension PlaybackSessionCacheClient: DependencyKey {
  static var liveValue: Self {
    .live(directory: ChildScopedDiskJSONCache<CachedPlaybackSession>.directory(
      named: "PlaybackSessionCache",
    ))
  }

  static let testValue = Self.noop
}

extension DependencyValues {
  var playbackSessionCache: PlaybackSessionCacheClient {
    get { self[PlaybackSessionCacheClient.self] }
    set { self[PlaybackSessionCacheClient.self] = newValue }
  }
}

extension PlaybackSessionCacheClient {
  static func live(directory: URL) -> Self {
    let diskCache = ChildScopedDiskJSONCache<CachedPlaybackSession>(
      directory: directory,
      isValid: { $0.playbackSession != nil },
    )
    return Self(
      _load: {
        @Dependency(\.keychain) var keychain
        guard let childId = keychain.loadConnection()?.childId else { return nil }
        return try await Task.detached(priority: .utility) {
          try diskCache.load(childId: childId)
        }.value
      },
      _save: { session in
        @Dependency(\.keychain) var keychain
        guard let childId = keychain.loadConnection()?.childId else { return }
        try await Task.detached(priority: .utility) {
          try diskCache.save(session, childId: childId)
        }.value
      },
      _delete: {
        @Dependency(\.keychain) var keychain
        guard let childId = keychain.loadConnection()?.childId else { return }
        await Task.detached(priority: .utility) {
          try? diskCache.delete(childId: childId)
        }.value
      },
    )
  }

  static let noop = Self(
    _load: { nil },
    _save: { _ in },
    _delete: {},
  )
}

struct CachedPlaybackSession: Codable, Equatable, Sendable {
  var items: [PlaybackItem]
  var currentIndex: Int
  var progress: PlaybackProgress

  init(
    items: [PlaybackItem],
    currentIndex: Int,
    progress: PlaybackProgress,
  ) {
    self.items = items
    self.currentIndex = currentIndex
    self.progress = progress
  }

  init(session: PlaybackFeature.Session) {
    self.init(
      items: session.albumQueue.items,
      currentIndex: session.albumQueue.currentIndex,
      progress: session.progress,
    )
  }

  var playbackSession: PlaybackFeature.Session? {
    guard !self.items.isEmpty else { return nil }
    return PlaybackFeature.Session(
      playStatus: .paused,
      albumQueue: .init(items: self.items, currentIndex: self.currentIndex),
      progress: PlaybackProgress(
        elapsedTime: self.progress.elapsedTime,
        duration: self.progress.duration,
      ),
    )
  }
}
