import CustomDump
import Dependencies
import Foundation
import Testing

@testable import LibTCA

struct LibraryCollectionRecencyClientTests {
  @Test
  func roundTripsAndDoesNotLoseNewerConcurrentState() async throws {
    let directory = try temporaryDirectory(named: "LibraryCollectionRecencyClient")
    defer { try? FileManager.default.removeItem(at: directory) }
    let client = LibraryCollectionRecencyClient.live(directory: directory)
    let connection = MusicAppConnection(
      token: UUID(1),
      childId: UUID(2),
      childName: "Harriet",
    )
    let connectionData = try JSONEncoder().encode(connection)
    let album = LibraryCollectionIdentity(kind: .album, id: "album")
    let playlist = LibraryCollectionIdentity(kind: .playlist, id: UUID(3).uuidString)
    let observedAt = Date(timeIntervalSince1970: 1)
    let newerPlayedAt = Date(timeIntervalSince1970: 30)
    let olderPlayedAt = Date(timeIntervalSince1970: 20)
    var newer = LibraryCollectionRecency()
    newer.recordPlay(of: album, observedAddedAt: observedAt, at: newerPlayedAt)
    newer.recordPlay(of: playlist, observedAddedAt: observedAt, at: newerPlayedAt)
    var stale = LibraryCollectionRecency()
    stale.recordPlay(of: album, observedAddedAt: observedAt, at: olderPlayedAt)

    let loaded = await withDependencies {
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      await client.save(newer)
      await client.save(stale)
      return await client.load()
    }

    expectNoDifference(loaded, newer)
  }
}
