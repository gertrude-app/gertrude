import CustomDump
import Foundation
import Testing

@testable import LibTCA

struct PlaybackSessionCacheClientTests {
  @Test
  func roundTripsPlaybackSession() throws {
    let directory = try temporaryDirectory(named: "roundTripsPlaybackSession")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = PlaybackSessionDiskCache(directory: directory)

    try cache.save(.mock, childId: childId)

    let loaded = try cache.load(childId: childId)
    expectNoDifference(loaded, .mock)
  }

  @Test
  func returnsNilWhenCacheIsMissing() throws {
    let directory = try temporaryDirectory(named: "returnsNilWhenCacheIsMissing")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = PlaybackSessionDiskCache(directory: directory)

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForMalformedCache() throws {
    let directory = try temporaryDirectory(named: "returnsNilForMalformedCache")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = PlaybackSessionDiskCache(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: cache.fileURL(childId: childId))

    let loaded = try cache.load(childId: childId)

    expectNoDifference(loaded, nil)
  }

  @Test
  func returnsNilForUnsupportedCacheVersion() throws {
    let directory = try temporaryDirectory(named: "returnsNilForUnsupportedCacheVersion")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = PlaybackSessionDiskCache(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data(
      #"{"session":{"currentIndex":0,"items":[],"progress":{"duration":0,"elapsedTime":0}},"version":0}"#
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
    let cache = PlaybackSessionDiskCache(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data(
      #"{"session":{"currentIndex":0,"items":[],"progress":{"duration":0,"elapsedTime":0}},"version":1}"#
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
    let cache = PlaybackSessionDiskCache(directory: directory)

    try cache.save(.mock, childId: childId)
    try cache.save(.otherMock, childId: otherChildId)
    try cache.delete(childId: childId)

    let deleted = try cache.load(childId: childId)
    let preserved = try cache.load(childId: otherChildId)
    expectNoDifference(deleted, nil)
    expectNoDifference(preserved, .otherMock)
  }
}

private let childId = UUID(uuidString: "CAFEBABE-CAFE-BABE-CAFE-BABECAFEBABE")!
private let otherChildId = UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!

private extension CachedPlaybackSession {
  static let mock = Self(
    items: [
      PlaybackItem(
        id: "track-1",
        title: "Track 1",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/artwork.jpg"),
        albumID: "album-1",
      ),
      PlaybackItem(
        id: "track-2",
        title: "Track 2",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/artwork.jpg"),
        albumID: "album-1",
      ),
    ],
    currentIndex: 1,
    progress: .init(elapsedTime: 42, duration: 180),
  )

  static let otherMock = Self(
    items: [
      PlaybackItem(
        id: "other-track",
        title: "Other Track",
        artistName: "Other Artist",
        artworkURL: nil,
      ),
    ],
    currentIndex: 0,
    progress: .init(elapsedTime: 12, duration: 120),
  )
}

private func temporaryDirectory(named name: String) throws -> URL {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    "PlaybackSessionCacheClientTests",
    isDirectory: true,
  )
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  let directory = root.appendingPathComponent(name, isDirectory: true)
  try? FileManager.default.removeItem(at: directory)
  return directory
}
