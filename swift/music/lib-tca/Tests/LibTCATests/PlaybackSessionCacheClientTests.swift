import CustomDump
import Foundation
import Testing

@testable import LibTCA

struct PlaybackSessionCacheClientTests {
  @Test
  func roundTripsPlaybackSession() throws {
    let directory = try temporaryDirectory(named: "roundTripsPlaybackSession")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackSessionCache(directory: directory)

    try cache.save(.mock, childId: childId)

    let loaded = try cache.load(childId: childId)
    expectNoDifference(loaded, .mock)
  }

  @Test
  func returnsNilWhenCacheIsMissing() throws {
    let directory = try temporaryDirectory(named: "returnsNilWhenCacheIsMissing")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackSessionCache(directory: directory)

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForMalformedCache() throws {
    let directory = try temporaryDirectory(named: "returnsNilForMalformedCache")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackSessionCache(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: cache.fileURL(childId: childId))

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForUnsupportedCacheVersion() throws {
    let directory = try temporaryDirectory(named: "returnsNilForUnsupportedCacheVersion")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackSessionCache(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data(
      #"{"value":{"currentIndex":0,"items":[],"progress":{"duration":0,"elapsedTime":0}},"version":0}"#
        .utf8,
    )
    .write(to: cache.fileURL(childId: childId))

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForEmptySession() throws {
    let directory = try temporaryDirectory(named: "returnsNilForEmptySession")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackSessionCache(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data(
      #"{"value":{"currentIndex":0,"items":[],"progress":{"duration":0,"elapsedTime":0}},"version":1}"#
        .utf8,
    )
    .write(to: cache.fileURL(childId: childId))

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func deleteRemovesOnlyRequestedChildCache() throws {
    let directory = try temporaryDirectory(named: "deleteRemovesOnlyRequestedChildCache")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = playbackSessionCache(directory: directory)

    try cache.save(.mock, childId: childId)
    try cache.save(.otherMock, childId: otherChildId)
    try cache.delete(childId: childId)

    let deleted = try cache.load(childId: childId)
    let preserved = try cache.load(childId: otherChildId)
    expectNoDifference(deleted, nil)
    expectNoDifference(preserved, .otherMock)
  }
}

private func playbackSessionCache(
  directory: URL,
) -> ChildScopedDiskJSONCache<CachedPlaybackSession> {
  ChildScopedDiskJSONCache<CachedPlaybackSession>(
    directory: directory,
    isValid: { $0.playbackSession != nil },
  )
}
