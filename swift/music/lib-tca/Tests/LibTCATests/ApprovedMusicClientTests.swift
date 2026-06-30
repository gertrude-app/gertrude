import CustomDump
import Dependencies
import Foundation
import MusicRoute
import Testing

@testable import LibTCA

@MainActor
struct ApprovedMusicClientTests {
  @Test
  func liveClientCachesSuccessfulApiLoad() async throws {
    let writes = SavedCacheWrites()
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    let library = try await withDependencies {
      $0.api.getApprovedMusicLibrary = { token in
        #expect(token == approvedMusicClientConnection.token)
        return remoteApprovedMusicLibrary
      }
      $0.approvedMusicLibraryCache._save = { library, childId in
        await writes.append(library: library, childId: childId)
      }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
    }

    let savedWrites = await writes.all()
    expectNoDifference(library, approvedMusicLibrary)
    expectNoDifference(savedWrites, [
      .init(library: approvedMusicLibrary, childId: approvedMusicClientConnection.childId),
    ])
  }

  @Test
  func liveClientIgnoresCacheWriteFailure() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    let library = try await withDependencies {
      $0.api.getApprovedMusicLibrary = { _ in remoteApprovedMusicLibrary }
      $0.approvedMusicLibraryCache._save = { _, _ in throw TestError() }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
    }

    expectNoDifference(library, approvedMusicLibrary)
  }

  @Test
  func liveClientLoadsCachedLibraryForCurrentChild() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    let library = await withDependencies {
      $0.approvedMusicLibraryCache._load = { childId in
        #expect(childId == approvedMusicClientConnection.childId)
        return approvedMusicLibrary
      }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      await ApprovedMusicClient.liveValue.loadCachedApprovedLibrary()
    }

    expectNoDifference(library, approvedMusicLibrary)
  }

  @Test
  func liveClientReturnsNilForCachedLibraryWithoutConnection() async {
    let library = await withDependencies {
      $0.keychain._load = { _ in nil }
    } operation: {
      await ApprovedMusicClient.liveValue.loadCachedApprovedLibrary()
    }

    expectNoDifference(library, nil)
  }

  @Test
  func liveClientReturnsNilWhenCachedLibraryLoadFails() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    let library = await withDependencies {
      $0.approvedMusicLibraryCache._load = { _ in throw TestError() }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      await ApprovedMusicClient.liveValue.loadCachedApprovedLibrary()
    }

    expectNoDifference(library, nil)
  }

  @Test
  func mockLibraryIsUsable() async throws {
    let library = try await ApprovedMusicClient.mock.loadRemoteApprovedLibrary()

    #expect(!library.isEmpty)
    #expect(Set(library.albums.map(\.id)).count == library.albums.count)

    for album in library.albums {
      #expect(!album.tracks.isEmpty)
      #expect(Set(album.tracks.map(\.id)).count == album.tracks.count)
    }
  }

  @Test
  func emptyLibraryIsAvailableForTestsAndPreviews() async throws {
    let library = try await ApprovedMusicClient.empty.loadRemoteApprovedLibrary()

    #expect(library.isEmpty)
  }
}

private actor SavedCacheWrites {
  private var writes: [SavedCacheWrite] = []

  func append(library: ApprovedMusicLibrary, childId: UUID) {
    self.writes.append(.init(library: library, childId: childId))
  }

  func all() -> [SavedCacheWrite] {
    self.writes
  }
}

private struct SavedCacheWrite: Equatable {
  var library: ApprovedMusicLibrary
  var childId: UUID
}

private let approvedMusicClientConnection = MusicAppConnection(
  token: UUID(uuidString: "2E256D99-CAB5-4C71-81BF-87590A22B382")!,
  childId: UUID(uuidString: "46FAF3DE-6A7A-4C72-9275-1297D10F8A89")!,
  childName: "Harriet",
)

private let remoteApprovedMusicLibrary = GetApprovedMusicLibrary.Output(albums: [
  .init(
    id: "album-1",
    title: "Library Album",
    artistName: "Library Artist",
    artworkUrl: "https://example.com/album.jpg",
    trackCount: 1,
    showsArtwork: true,
    tracks: [
      .init(
        id: "track-1",
        title: "Library Track",
        artistName: "Track Artist",
        artworkUrl: "https://example.com/track.jpg",
      ),
    ],
  ),
])

private let approvedMusicLibrary = ApprovedMusicLibrary(albums: [
  .init(
    id: "album-1",
    title: "Library Album",
    artistName: "Library Artist",
    artworkURL: URL(string: "https://example.com/album.jpg"),
    tracks: [
      .init(
        id: "track-1",
        title: "Library Track",
        artistName: "Track Artist",
        artworkURL: URL(string: "https://example.com/track.jpg"),
      ),
    ],
  ),
])

private struct TestError: Error {}
