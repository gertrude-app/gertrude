import CustomDump
import Dependencies
import Foundation
import Testing

@testable import LibTCA

struct PlaybackSessionCacheClientTests {
  @Test
  func roundTripsPlaybackCheckpoint() throws {
    let directory = try temporaryDirectory(named: "roundTripsPlaybackCheckpoint")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackCheckpointCache(directory: directory)

    try cache.save(.mock, childId: childId)

    let loaded = try cache.load(childId: childId)
    expectNoDifference(loaded, .mock)
  }

  @Test
  func returnsNilWhenCacheIsMissing() throws {
    let directory = try temporaryDirectory(named: "returnsNilWhenCacheIsMissing")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackCheckpointCache(directory: directory)

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForMalformedCache() throws {
    let directory = try temporaryDirectory(named: "returnsNilForMalformedCache")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackCheckpointCache(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: cache.fileURL(childId: childId))

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForUnsupportedCacheVersion() throws {
    let directory = try temporaryDirectory(named: "returnsNilForUnsupportedCacheVersion")
    defer { try? FileManager.default.removeItem(at: directory) }
    let oldCache = ChildScopedDiskJSONCache<PlaybackCheckpoint>(
      directory: directory,
      version: 1,
    )
    try oldCache.save(.mock, childId: childId)

    let loaded = try playbackCheckpointCache(directory: directory).load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForEmptyCheckpoint() throws {
    let directory = try temporaryDirectory(named: "returnsNilForEmptyCheckpoint")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackCheckpointCache(directory: directory)
    try cache.save(
      PlaybackCheckpoint(songIDs: [], currentIndex: 0, elapsedTime: 0),
      childId: childId,
    )

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func migratesLegacyPlaybackSession() async throws {
    let directory = try temporaryDirectory(named: "migratesLegacyPlaybackSession")
    defer { try? FileManager.default.removeItem(at: directory) }
    let legacyCache = ChildScopedDiskJSONCache<CachedPlaybackSession>(
      directory: directory,
      version: 1,
      isValid: { $0.playbackSession != nil },
    )
    try legacyCache.save(.mock, childId: childId)
    let connectionData = try JSONEncoder().encode(MusicAppConnection(
      token: UUID(3),
      childId: childId,
      childName: "Child",
    ))
    let client = PlaybackSessionCacheClient.live(directory: directory)

    let loaded = try await withDependencies {
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await client.load()
    }

    let expected = PlaybackCheckpoint(legacySession: .mock)
    expectNoDifference(loaded, expected)
    try expectNoDifference(
      playbackCheckpointCache(directory: directory).load(childId: childId),
      expected,
    )
    try expectNoDifference(legacyCache.load(childId: childId), nil)
  }

  @Test
  func liveDeleteRemovesCheckpointAndLegacySession() async throws {
    let directory = try temporaryDirectory(named: "liveDeleteRemovesCheckpointAndLegacySession")
    defer { try? FileManager.default.removeItem(at: directory) }
    let checkpointCache = playbackCheckpointCache(directory: directory)
    let legacyCache = ChildScopedDiskJSONCache<CachedPlaybackSession>(
      directory: directory,
      version: 1,
      isValid: { $0.playbackSession != nil },
    )
    try checkpointCache.save(.mock, childId: childId)
    try legacyCache.save(.mock, childId: childId)
    let connectionData = try JSONEncoder().encode(MusicAppConnection(
      token: UUID(3),
      childId: childId,
      childName: "Child",
    ))
    let client = PlaybackSessionCacheClient.live(directory: directory)

    await withDependencies {
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      await client.delete()
    }

    try expectNoDifference(checkpointCache.load(childId: childId), nil)
    try expectNoDifference(legacyCache.load(childId: childId), nil)
  }

  @Test
  func checkpointPersistsOnlyCurrentAndUpcomingItems() {
    let items = [
      playbackItem("consumed"),
      playbackItem("current").withAlbumID("album-current"),
      playbackItem("up-next").withAlbumID("album-next"),
    ]
    let session = PlaybackFeature.Session(
      playStatus: .paused,
      queue: .init(items: items, currentIndex: 1),
      progress: .init(elapsedTime: 42, duration: 180),
    )

    let checkpoint = PlaybackCheckpoint(
      session: session,
      sourceAlbumIDs: ["consumed": "album-consumed"],
    )

    expectNoDifference(
      checkpoint,
      PlaybackCheckpoint(
        songIDs: ["current", "up-next"],
        currentIndex: 0,
        elapsedTime: 42,
        durationFallback: 180,
        sourceAlbumHints: [
          .init(songID: "current", albumID: "album-current"),
          .init(songID: "up-next", albumID: "album-next"),
        ],
      ),
    )
  }

  @Test
  func checkpointPersistsPlaylistSourcePerDuplicateOccurrence() {
    let firstSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let secondSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let session = PlaybackFeature.Session(
      playStatus: .paused,
      queue: .init(items: [
        playbackItem("duplicate").withPlaylistSource(firstSource),
        playbackItem("duplicate").withPlaylistSource(secondSource),
      ]),
      progress: .init(elapsedTime: 42, duration: 180),
    )

    let checkpoint = PlaybackCheckpoint(session: session, sourceAlbumIDs: [:])

    expectNoDifference(checkpoint.playlistSourceHints, [firstSource, secondSource])
  }

  @Test
  func existingCheckpointNormalizesToCurrentAndUpcomingItems() {
    let currentSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let nextSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let checkpoint = PlaybackCheckpoint(
      songIDs: ["consumed", "current", "up-next"],
      currentIndex: 1,
      elapsedTime: 42,
      durationFallback: 180,
      sourceAlbumHints: [
        .init(songID: "consumed", albumID: "album-consumed"),
        .init(songID: "current", albumID: "album-current"),
      ],
      playlistSourceHints: [nil, currentSource, nextSource],
    )

    expectNoDifference(
      checkpoint.activeQueue,
      PlaybackCheckpoint(
        songIDs: ["current", "up-next"],
        currentIndex: 0,
        elapsedTime: 42,
        durationFallback: 180,
        sourceAlbumHints: [
          .init(songID: "current", albumID: "album-current"),
        ],
        playlistSourceHints: [currentSource, nextSource],
      ),
    )
  }

  @Test
  func deleteRemovesOnlyRequestedChildCache() throws {
    let directory = try temporaryDirectory(named: "deleteRemovesOnlyRequestedChildCache")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackCheckpointCache(directory: directory)

    try cache.save(.mock, childId: childId)
    try cache.save(.otherMock, childId: otherChildId)
    try cache.delete(childId: childId)

    let deleted = try cache.load(childId: childId)
    let preserved = try cache.load(childId: otherChildId)
    expectNoDifference(deleted, nil)
    expectNoDifference(preserved, .otherMock)
  }
}

private func playbackCheckpointCache(
  directory: URL,
) -> ChildScopedDiskJSONCache<PlaybackCheckpoint> {
  ChildScopedDiskJSONCache<PlaybackCheckpoint>(
    directory: directory,
    version: 2,
    isValid: \.isValid,
  )
}
