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
    let remoteLibrary = try JSONDecoder().decode(
      GetApprovedMusicLibrary_v2.Output.self,
      from: Data(v2ApprovedMusicLibraryJSON.utf8),
    )

    let library = try await withDependencies {
      $0.api.getApprovedMusicLibrary = { token in
        #expect(token == approvedMusicClientConnection.token)
        return remoteLibrary
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
  func liveClientLoadsAlbumTracks() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    let tracks = try await withDependencies {
      $0.api.getApprovedMusicAlbumTracks = { token, albumID in
        #expect(token == approvedMusicClientConnection.token)
        #expect(albumID == "album-1")
        return remoteApprovedAlbumTracks
      }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.loadAlbumTracks(albumID: "album-1")
    }

    expectNoDifference(tracks, approvedAlbumTracks)
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
    #expect(Set(library.artists.map(\.id)).count == library.artists.count)

    for album in library.albums {
      #expect(!album.tracks.isEmpty)
      #expect(Set(album.tracks.map(\.id)).count == album.tracks.count)
    }

    let tracks = try await ApprovedMusicClient.mock.loadAlbumTracks(library.albums[0].id)
    expectNoDifference(tracks, library.albums[0].tracks)
  }

  @Test
  func emptyLibraryIsAvailableForTestsAndPreviews() async throws {
    let library = try await ApprovedMusicClient.empty.loadRemoteApprovedLibrary()
    let tracks = try await ApprovedMusicClient.empty.loadAlbumTracks(albumID: "album-1")

    #expect(library.isEmpty)
    expectNoDifference(tracks, [])
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
  token: UUID(1),
  childId: UUID(2),
  childName: "Harriet",
)

private let remoteApprovedMusicLibrary = GetApprovedMusicLibrary_v2.Output(
  albums: [
    .init(
      id: "album-1",
      title: "Library Album",
      artistName: "Library Artist",
      artworkUrl: "https://example.com/album.jpg",
      trackCount: 1,
      showsArtwork: true,
    ),
  ],
  artists: [
    .init(
      id: "artist-1",
      name: "Library Artist",
      catalogMetadata: .init(
        artwork: .init(
          url: "https://example.com/artist/{w}x{h}bb.jpg",
          width: 1080,
          height: 1080,
          bgColor: "102030",
          textColor1: "ffffff",
          textColor2: "eeeeee",
          textColor3: "dddddd",
          textColor4: "cccccc",
        ),
        editorialNotes: .init(
          tagline: "Tagline",
          short: "Short <b>note</b>",
          standard: "Standard note",
          name: "Notes Name",
        ),
        appleMusicUrl: "https://music.apple.com/us/artist/library-artist/artist-1",
        genreNames: ["Folk", "Classical"],
      ),
    ),
  ],
)

private let remoteApprovedAlbumTracks: GetApprovedMusicAlbumTracks.Output = [
  .init(
    id: "track-1",
    title: "Library Track",
    artistName: "Track Artist",
    artworkUrl: "https://example.com/track.jpg",
  ),
]

private let approvedAlbumTracks = [
  ApprovedTrack(
    id: "track-1",
    title: "Library Track",
    artistName: "Track Artist",
    artworkURL: URL(string: "https://example.com/track.jpg"),
  ),
]

private let approvedMusicLibrary = ApprovedMusicLibrary(
  albums: [
    .init(
      id: "album-1",
      title: "Library Album",
      artistName: "Library Artist",
      artworkURL: URL(string: "https://example.com/album.jpg"),
    ),
  ],
  artists: [
    .init(
      id: "artist-1",
      name: "Library Artist",
      catalogMetadata: .init(
        artwork: .init(
          url: "https://example.com/artist/{w}x{h}bb.jpg",
          width: 1080,
          height: 1080,
          bgColor: "102030",
          textColor1: "ffffff",
          textColor2: "eeeeee",
          textColor3: "dddddd",
          textColor4: "cccccc",
        ),
        editorialNotes: .init(
          tagline: "Tagline",
          short: "Short <b>note</b>",
          standard: "Standard note",
          name: "Notes Name",
        ),
        appleMusicUrl: "https://music.apple.com/us/artist/library-artist/artist-1",
        genreNames: ["Folk", "Classical"],
      ),
    ),
  ],
)

private let v2ApprovedMusicLibraryJSON = #"""
{
  "albums": [
    {
      "id": "album-1",
      "title": "Library Album",
      "artistName": "Library Artist",
      "artworkUrl": "https://example.com/album.jpg",
      "trackCount": 1,
      "showsArtwork": true
    }
  ],
  "artists": [
    {
      "id": "artist-1",
      "name": "Library Artist",
      "catalogMetadata": {
        "artwork": {
          "url": "https://example.com/artist/{w}x{h}bb.jpg",
          "width": 1080,
          "height": 1080,
          "bgColor": "102030",
          "textColor1": "ffffff",
          "textColor2": "eeeeee",
          "textColor3": "dddddd",
          "textColor4": "cccccc"
        },
        "editorialNotes": {
          "tagline": "Tagline",
          "short": "Short <b>note</b>",
          "standard": "Standard note",
          "name": "Notes Name"
        },
        "appleMusicUrl": "https://music.apple.com/us/artist/library-artist/artist-1",
        "genreNames": ["Folk", "Classical"]
      }
    }
  ]
}
"""#
