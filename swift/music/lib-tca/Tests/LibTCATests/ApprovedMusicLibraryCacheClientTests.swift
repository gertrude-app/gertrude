import CustomDump
import Foundation
import Testing

@testable import LibTCA

struct ApprovedMusicLibraryCacheClientTests {
  @Test
  func roundTripsApprovedLibrary() async throws {
    let directory = try temporaryDirectory(named: "roundTripsApprovedLibrary")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = ApprovedMusicLibraryCacheClient.live(directory: directory)

    try await cache.save(.mock, childId: childId)

    let loaded = try await cache.load(childId: childId)
    expectNoDifference(loaded, .mock)
  }

  @Test
  func returnsNilWhenCacheIsMissing() async throws {
    let directory = try temporaryDirectory(named: "returnsNilWhenCacheIsMissing")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = ApprovedMusicLibraryCacheClient.live(directory: directory)

    let loaded = try await cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForMalformedCache() async throws {
    let directory = try temporaryDirectory(named: "returnsNilForMalformedCache")
    defer { try? FileManager.default.removeItem(at: directory) }
    let diskCache = ChildScopedDiskJSONCache<ApprovedMusicLibrary>(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: diskCache.fileURL(childId: childId))
    let cache = ApprovedMusicLibraryCacheClient.live(directory: directory)

    let loaded = try await cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForLegacyCacheVersion() async throws {
    let directory = try temporaryDirectory(named: "returnsNilForLegacyCacheVersion")
    defer { try? FileManager.default.removeItem(at: directory) }
    let legacyDiskCache = ChildScopedDiskJSONCache<ApprovedMusicLibrary>(
      directory: directory,
      version: 1,
    )
    try legacyDiskCache.save(.mock, childId: childId)
    let cache = ApprovedMusicLibraryCacheClient.live(directory: directory)

    let loaded = try await cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForUnsupportedSnapshotSchema() async throws {
    let directory = try temporaryDirectory(named: "returnsNilForUnsupportedSnapshotSchema")
    defer { try? FileManager.default.removeItem(at: directory) }
    let diskCache = ChildScopedDiskJSONCache<ApprovedMusicLibrary>(
      directory: directory,
      version: 2,
    )
    var unsupported = ApprovedMusicLibrary.mock
    unsupported.schemaVersion = 3
    try diskCache.save(unsupported, childId: childId)
    let cache = ApprovedMusicLibraryCacheClient.live(directory: directory)

    let loaded = try await cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForIncompleteSnapshot() async throws {
    let directory = try temporaryDirectory(named: "returnsNilForIncompleteSnapshot")
    defer { try? FileManager.default.removeItem(at: directory) }
    let diskCache = ChildScopedDiskJSONCache<ApprovedMusicLibrary>(
      directory: directory,
      version: 2,
    )
    var incomplete = ApprovedMusicLibrary.mock
    incomplete.albums.append(incomplete.albums[0])
    try diskCache.save(incomplete, childId: childId)
    let cache = ApprovedMusicLibraryCacheClient.live(directory: directory)

    let loaded = try await cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func deleteRemovesOnlyRequestedChildCache() async throws {
    let directory = try temporaryDirectory(named: "deleteRemovesOnlyRequestedChildCache")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = ApprovedMusicLibraryCacheClient.live(directory: directory)

    try await cache.save(.mock, childId: childId)
    try await cache.save(.empty, childId: otherChildId)
    await cache.delete(childId: childId)

    let deleted = try await cache.load(childId: childId)
    let preserved = try await cache.load(childId: otherChildId)
    expectNoDifference(deleted, nil)
    expectNoDifference(preserved, .empty)
  }
}
