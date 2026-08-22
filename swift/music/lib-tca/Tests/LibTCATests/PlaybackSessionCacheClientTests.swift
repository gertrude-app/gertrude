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
  func playbackContextPersistsArtistSourceAndDecodesLegacyContext() throws {
    let context = PlaybackContext(
      identity: .init(kind: .artist, id: "artist"),
      title: "Artist",
      artistSource: .topSongs,
    )

    let decoded = try JSONDecoder().decode(
      PlaybackContext.self,
      from: JSONEncoder().encode(context),
    )
    let legacy = try JSONDecoder().decode(
      PlaybackContext.self,
      from: Data(#"{"identity":{"id":"artist","kind":"artist"},"title":"Artist"}"#.utf8),
    )

    expectNoDifference(decoded, context)
    expectNoDifference(
      legacy,
      PlaybackContext(identity: context.identity, title: context.title),
    )
  }

  @Test
  func roundTripsFullPlaybackSource() throws {
    let items = [
      playbackItem("first"),
      playbackItem("duplicate"),
      playbackItem("duplicate"),
    ]
    let context = PlaybackContext(
      identity: .init(kind: .playlist, id: "playlist"),
      title: "Playlist",
    )
    var playbackSource = PlaybackSource(
      items: items,
      selectedIndex: 1,
      context: context,
    )
    playbackSource.remove(2)
    let infinitePlaybackPlan = InfinitePlaybackPlan(
      remainingSourceEntryIDs: [0],
      generatedItems: [playbackItem("generated")],
    )
    let checkpoint = PlaybackCheckpoint(
      session: .init(queue: .init(items: Array(items.dropFirst()))),
      infinitePlaybackPlan: infinitePlaybackPlan,
      playbackSource: playbackSource,
      context: context,
      progress: .zero,
      sourceAlbumIDs: [:],
    )

    let decoded = try JSONDecoder().decode(
      PlaybackCheckpoint.self,
      from: JSONEncoder().encode(checkpoint),
    )

    expectNoDifference(decoded.infinitePlaybackPlan, infinitePlaybackPlan)
    expectNoDifference(decoded.playbackSource, playbackSource)
    expectNoDifference(decoded.activeQueue.infinitePlaybackPlan, infinitePlaybackPlan)
    expectNoDifference(decoded.activeQueue.playbackSource, playbackSource)
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
  func rejectsSourceOccurrenceIdentityWithoutSource() {
    let checkpoint = PlaybackCheckpoint(
      songIDs: ["track"],
      currentIndex: 0,
      elapsedTime: 0,
      sourceEntryIDs: [0],
    )

    #expect(!checkpoint.isValid)
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
      isValid: \.isValid,
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
      isValid: \.isValid,
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
    )

    let checkpoint = PlaybackCheckpoint(
      session: session,
      progress: .init(elapsedTime: 42, duration: 180),
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
    )

    let checkpoint = PlaybackCheckpoint(
      session: session,
      progress: .init(elapsedTime: 42, duration: 180),
      sourceAlbumIDs: [:],
    )

    expectNoDifference(checkpoint.playlistSourceHints, [firstSource, secondSource])
  }

  @Test
  func checkpointPersistsSourceOccurrenceIdentity() throws {
    let duplicate = playbackItem("duplicate")
    let source = PlaybackSource(
      items: [duplicate, duplicate],
      selectedIndex: 0,
      context: nil,
    )
    let entries = [
      PlaybackQueueEntry(
        id: "first",
        item: duplicate.withQueueRole(.context),
        sourceEntryID: 0,
      ),
      PlaybackQueueEntry(
        id: "explicit",
        item: playbackItem("explicit").withQueueRole(.queued),
      ),
      PlaybackQueueEntry(
        id: "second",
        item: duplicate.withQueueRole(.context),
        sourceEntryID: 1,
      ),
    ]
    let queue = try #require(PlaybackFeature.Queue(
      entries: entries,
      currentEntryID: "first",
    ))
    let checkpoint = PlaybackCheckpoint(
      session: .init(queue: queue),
      playbackSource: source,
      progress: .zero,
      sourceAlbumIDs: [:],
    )

    let decoded = try JSONDecoder().decode(
      PlaybackCheckpoint.self,
      from: JSONEncoder().encode(checkpoint),
    )

    expectNoDifference(decoded.sourceEntryIDs, [0, nil, 1])
    expectNoDifference(decoded.playbackSource, source)
  }

  @Test
  func existingCheckpointNormalizesToCurrentAndUpcomingItems() {
    let currentSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let nextSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let playbackSource = PlaybackSource(
      items: [
        playbackItem("consumed"),
        playbackItem("current"),
        playbackItem("up-next"),
      ],
      selectedIndex: 0,
      context: nil,
    )
    let checkpoint = PlaybackCheckpoint(
      songIDs: ["consumed", "current", "up-next"],
      currentIndex: 1,
      elapsedTime: 42,
      durationFallback: 180,
      sourceAlbumHints: [
        .init(songID: "consumed", albumID: "album-consumed"),
        .init(songID: "current", albumID: "album-current"),
      ],
      playbackSource: playbackSource,
      playlistSourceHints: [nil, currentSource, nextSource],
      sourceEntryIDs: [0, 1, 2],
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
        playbackSource: playbackSource,
        playlistSourceHints: [currentSource, nextSource],
        sourceEntryIDs: [1, 2],
      ),
    )
  }

  @Test
  func checkpointPersistsPlaybackContextAndQueueRoles() throws {
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    let session = PlaybackFeature.Session(
      queue: .init(items: [
        playbackItem("current").withQueueRole(.context),
        playbackItem("queued").withQueueRole(.queued),
        playbackItem("following").withQueueRole(.context),
      ]),
    )

    let checkpoint = PlaybackCheckpoint(
      session: session,
      context: context,
      progress: .zero,
      sourceAlbumIDs: [:],
    )

    let decoded = try JSONDecoder().decode(
      PlaybackCheckpoint.self,
      from: JSONEncoder().encode(checkpoint),
    )

    expectNoDifference(decoded.context, context)
    expectNoDifference(decoded.queueRoles, [.context, .queued, .context])
  }

  @Test
  func decodesCheckpointSavedBeforeQueueMetadata() throws {
    let previousCheckpoint = PlaybackCheckpointV2(
      songIDs: ["track-1"],
      currentIndex: 0,
      elapsedTime: 12,
      durationFallback: 180,
      sourceAlbumHints: [
        .init(songID: "track-1", albumID: "album-1"),
      ],
      playlistSourceHints: [nil],
    )

    let decoded = try JSONDecoder().decode(
      PlaybackCheckpoint.self,
      from: JSONEncoder().encode(previousCheckpoint),
    )

    expectNoDifference(decoded.playbackSource, nil)
    expectNoDifference(decoded.sourceEntryIDs, nil)
    expectNoDifference(
      decoded,
      PlaybackCheckpoint(
        songIDs: ["track-1"],
        currentIndex: 0,
        elapsedTime: 12,
        durationFallback: 180,
        sourceAlbumHints: [
          .init(songID: "track-1", albumID: "album-1"),
        ],
        playlistSourceHints: [nil],
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

private struct PlaybackCheckpointV2: Encodable {
  var songIDs: [ApprovedTrack.ID]
  var currentIndex: Int
  var elapsedTime: TimeInterval
  var durationFallback: TimeInterval?
  var sourceAlbumHints: [PlaybackCheckpoint.SourceAlbumHint]
  var playlistSourceHints: [PlaylistPlaybackSource?]
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
