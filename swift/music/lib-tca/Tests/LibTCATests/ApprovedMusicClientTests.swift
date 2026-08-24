import CustomDump
import Dependencies
import Foundation
import LibViews
import MusicRoute
import PairQL
import Testing

@testable import LibTCA

@MainActor
struct ApprovedMusicClientTests {
  @Test
  func liveClientCachesSuccessfulApiLoad() async throws {
    let writes = SavedCacheWrites()
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let remoteLibrary = try decoder.decode(
      MusicLibrarySnapshot.self,
      from: Data(v2ApprovedMusicLibraryJSON.utf8),
    )

    let library = try await withDependencies {
      $0.api.getApprovedMusicLibrary = { token, knownRevision in
        #expect(token == approvedMusicClientConnection.token)
        #expect(knownRevision == nil)
        return .snapshot(remoteLibrary)
      }
      $0.approvedMusicLibraryCache._load = { _ in nil }
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
    #expect(library.albums[0].tracks[0].discNumber == nil)
    #expect(library.albums[0].tracks[0].trackNumber == nil)
    expectNoDifference(savedWrites, [
      .init(library: approvedMusicLibrary, childId: approvedMusicClientConnection.childId),
    ])
  }

  @Test
  func liveClientMapsLoggedOutLibraryLoadToInvalidConnection() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    do {
      _ = try await withDependencies {
        $0.api.getApprovedMusicLibrary = { _, _ in
          throw PqlError(
            id: "missing-token",
            requestId: "request-id",
            type: .loggedOut,
            debugMessage: "music app token not found",
          )
        }
        $0.approvedMusicLibraryCache._load = { _ in approvedMusicLibrary }
        $0.keychain._load = { key in
          key == .connection ? connectionData : nil
        }
      } operation: {
        try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
      }
      Issue.record("expected invalid connection")
    } catch let error as ApprovedMusicClientError {
      expectNoDifference(error, .invalidConnection)
    }
  }

  @Test
  func liveClientMapsLoggedOutMutationToInvalidConnection() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    do {
      _ = try await withDependencies {
        $0.api.createMusicPlaylist = { _, _ in
          throw PqlError(
            id: "missing-token",
            requestId: "request-id",
            type: .loggedOut,
            debugMessage: "music app token not found",
          )
        }
        $0.keychain._load = { key in
          key == .connection ? connectionData : nil
        }
      } operation: {
        try await ApprovedMusicClient.liveValue.createPlaylist(.init(name: "Road Trip"))
      }
      Issue.record("expected invalid connection")
    } catch let error as ApprovedMusicClientError {
      expectNoDifference(error, .invalidConnection)
    }
  }

  @Test
  func liveClientPreservesCatalogTrackViewData() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)
    var numberedRemote = remoteApprovedMusicLibrary
    numberedRemote.albums[0].tracks[0].discNumber = 2
    numberedRemote.albums[0].tracks[0].trackNumber = 7
    numberedRemote.playlists[0].entries[0].track.discNumber = 2
    numberedRemote.playlists[0].entries[0].track.trackNumber = 7
    let remote = numberedRemote

    let library = try await withDependencies {
      $0.api.getApprovedMusicLibrary = { _, _ in .snapshot(remote) }
      $0.approvedMusicLibraryCache._load = { _ in nil }
      $0.approvedMusicLibraryCache._save = { _, _ in }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
    }
    let track = library.albums[0].tracks[0]
    let viewData = TrackData(track: track)

    #expect(track.discNumber == 2)
    #expect(track.trackNumber == 7)
    #expect(viewData.duration == "3:00")
    #expect(viewData.discNumber == 2)
    #expect(viewData.trackNumber == 7)
  }

  @Test
  func liveClientCachesSuccessfulPlaylistMutation() async throws {
    let writes = SavedCacheWrites()
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)
    var changedRemote = remoteApprovedMusicLibrary
    changedRemote.revision = 8
    let remote = changedRemote
    var expected = approvedMusicLibrary
    expected.revision = 8

    let result = try await withDependencies {
      $0.api.createMusicPlaylist = { token, input in
        #expect(token == approvedMusicClientConnection.token)
        #expect(input == .init(name: "New Playlist"))
        return .updated(remote)
      }
      $0.approvedMusicLibraryCache._load = { _ in approvedMusicLibrary }
      $0.approvedMusicLibraryCache._save = { library, childId in
        await writes.append(library: library, childId: childId)
      }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.createPlaylist(.init(name: "New Playlist"))
    }

    let savedWrites = await writes.all()
    expectNoDifference(result, .updated(expected))
    expectNoDifference(savedWrites, [
      .init(library: expected, childId: approvedMusicClientConnection.childId),
    ])
  }

  @Test
  func liveClientMapsDuplicateConfirmationWithAuthoritativeLibrary() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)
    let confirmation = MusicPlaylistDuplicateConfirmation.track(
      playlistId: UUID(3),
      duplicate: .init(trackId: "track-1", title: "Library Track", existingCount: 1),
    )

    let result = try await withDependencies {
      $0.api.addSourceToMusicPlaylist = { _, _ in
        .duplicateConfirmationRequired(
          snapshot: remoteApprovedMusicLibrary,
          confirmation: confirmation,
        )
      }
      $0.approvedMusicLibraryCache._load = { _ in approvedMusicLibrary }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.addSourceToPlaylist(.init(
        playlistId: UUID(3),
        source: .track(trackId: "track-1", albumId: "album-1"),
      ))
    }

    expectNoDifference(
      result,
      .duplicateConfirmationRequired(
        library: approvedMusicLibrary,
        confirmation: confirmation,
      ),
    )
  }

  @Test
  func liveClientMapsBatchDuplicateConfirmationWithAuthoritativeLibrary() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)
    let confirmation = MusicPlaylistBatchDuplicateConfirmation(
      playlistId: UUID(3),
      duplicates: [.init(trackId: "track-1", title: "Library Track", existingCount: 1)],
    )
    let input = AddMusicBatchToPlaylist.Input(
      playlistId: UUID(3),
      sources: [.track(trackId: "track-1", albumId: "album-1")],
    )

    let result = try await withDependencies {
      $0.api.addMusicBatchToPlaylist = { _, receivedInput in
        #expect(receivedInput == input)
        return .batchDuplicateConfirmationRequired(
          snapshot: remoteApprovedMusicLibrary,
          confirmation: confirmation,
        )
      }
      $0.approvedMusicLibraryCache._load = { _ in approvedMusicLibrary }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.addMusicBatchToPlaylist(input)
    }

    expectNoDifference(
      result,
      .batchDuplicateConfirmationRequired(
        library: approvedMusicLibrary,
        confirmation: confirmation,
      ),
    )
  }

  @Test
  func liveClientReturnsCachedLibraryForUnchangedRevisionWithoutWriting() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    let library = try await withDependencies {
      $0.api.getApprovedMusicLibrary = { token, knownRevision in
        #expect(token == approvedMusicClientConnection.token)
        #expect(knownRevision == approvedMusicLibrary.revision)
        return .unchanged(revision: approvedMusicLibrary.revision)
      }
      $0.approvedMusicLibraryCache._load = { childId in
        #expect(childId == approvedMusicClientConnection.childId)
        return approvedMusicLibrary
      }
      $0.approvedMusicLibraryCache._save = { _, _ in
        Issue.record("unchanged snapshot should not rewrite cache")
      }
      $0.keychain._load = { key in
        key == .connection ? connectionData : nil
      }
    } operation: {
      try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
    }

    expectNoDifference(library, approvedMusicLibrary)
  }

  @Test
  func liveClientRejectsUnchangedResponseWithoutMatchingCache() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    await #expect(throws: ApprovedMusicClientError.self) {
      try await withDependencies {
        $0.api.getApprovedMusicLibrary = { _, knownRevision in
          #expect(knownRevision == nil)
          return .unchanged(revision: 7)
        }
        $0.approvedMusicLibraryCache._load = { _ in nil }
        $0.keychain._load = { key in
          key == .connection ? connectionData : nil
        }
      } operation: {
        try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
      }
    }
  }

  @Test
  func liveClientRejectsSnapshotOlderThanCache() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)
    var staleSnapshot = remoteApprovedMusicLibrary
    staleSnapshot.revision = approvedMusicLibrary.revision - 1
    let stale = staleSnapshot

    await #expect(throws: ApprovedMusicClientError.self) {
      try await withDependencies {
        $0.api.getApprovedMusicLibrary = { _, knownRevision in
          #expect(knownRevision == approvedMusicLibrary.revision)
          return .snapshot(stale)
        }
        $0.approvedMusicLibraryCache._load = { _ in approvedMusicLibrary }
        $0.approvedMusicLibraryCache._save = { _, _ in
          Issue.record("stale snapshot should not rewrite cache")
        }
        $0.keychain._load = { key in
          key == .connection ? connectionData : nil
        }
      } operation: {
        try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
      }
    }
  }

  @Test
  func liveClientRejectsIncompleteSnapshot() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)
    var incompleteSnapshot = remoteApprovedMusicLibrary
    incompleteSnapshot.artists[0].topSongs[0].id = "not-in-album"
    let incomplete = incompleteSnapshot

    await #expect(throws: ApprovedMusicClientError.self) {
      try await withDependencies {
        $0.api.getApprovedMusicLibrary = { _, _ in .snapshot(incomplete) }
        $0.approvedMusicLibraryCache._load = { _ in nil }
        $0.approvedMusicLibraryCache._save = { _, _ in
          Issue.record("incomplete snapshot should not write cache")
        }
        $0.keychain._load = { key in
          key == .connection ? connectionData : nil
        }
      } operation: {
        try await ApprovedMusicClient.liveValue.loadRemoteApprovedLibrary()
      }
    }
  }

  @Test
  func liveClientIgnoresCacheWriteFailure() async throws {
    let connectionData = try JSONEncoder().encode(approvedMusicClientConnection)

    let library = try await withDependencies {
      $0.api.getApprovedMusicLibrary = { _, _ in .snapshot(remoteApprovedMusicLibrary) }
      $0.approvedMusicLibraryCache._load = { _ in nil }
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
    #expect(Set(library.artists.map(\.id)).count == library.artists.count)

    for album in library.albums {
      #expect(!album.tracks.isEmpty)
      #expect(Set(album.tracks.map(\.id)).count == album.tracks.count)
      #expect(album.tracks.allSatisfy { $0.albumID == album.id })
    }
  }

  @Test
  func emptyLibraryIsAvailableForTestsAndPreviews() async throws {
    let library = try await ApprovedMusicClient.empty.loadRemoteApprovedLibrary()

    #expect(library.isEmpty)
  }

  @Test
  func mapsArtistDetailViewData() {
    let album = AlbumData(album: approvedMusicLibrary.albums[0])
    let artist = ArtistData(artist: approvedMusicLibrary.artists[0])

    #expect(album.trackCount == 1)
    #expect(album.releaseDate == "2024-04-12")
    #expect(album.releaseType == "Album")
    #expect(artist.topSongs.map(\.duration) == ["3:20"])
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

private let snapshotDate = Date(timeIntervalSince1970: 1000)

private let remoteApprovedMusicLibrary = MusicLibrarySnapshot(
  revision: 7,
  generatedAt: snapshotDate,
  albums: [
    .init(
      id: "album-1",
      title: "Library Album",
      artistName: "Library Artist",
      artworkUrl: "https://example.com/album.jpg",
      artwork: .init(
        url: "https://example.com/album/{w}x{h}bb.jpg",
        width: 1200,
        height: 1200,
        bgColor: "203040",
        textColor1: "ffffff",
        textColor2: "eeeeee",
        textColor3: "dddddd",
        textColor4: "cccccc",
      ),
      trackCount: 1,
      releaseDate: "2024-04-12",
      releaseType: "Album",
      showsArtwork: true,
      addedAt: snapshotDate,
      tracks: [
        .init(
          id: "track-1",
          title: "Library Track",
          artistName: "Track Artist",
          albumId: "album-1",
          albumTitle: "Library Album",
          artworkUrl: "https://example.com/track.jpg",
          durationInMillis: 180_000,
        ),
      ],
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
      releaseAlbumIds: ["album-1"],
      topSongs: [
        .init(
          id: "track-1",
          title: "Top Song",
          artistName: "Library Artist",
          albumId: "album-1",
          albumTitle: "Library Album",
          artworkUrl: "https://example.com/top-song.jpg",
          durationInMillis: 200_000,
        ),
      ],
      addedAt: snapshotDate,
    ),
  ],
  playlists: [
    .init(
      id: UUID(3),
      name: "Favorites",
      revision: 2,
      createdAt: snapshotDate,
      updatedAt: snapshotDate,
      entries: [
        .init(
          id: UUID(4),
          track: .init(
            id: "track-1",
            title: "Library Track",
            artistName: "Track Artist",
            albumId: "album-1",
            albumTitle: "Library Album",
            artworkUrl: "https://example.com/track.jpg",
            durationInMillis: 180_000,
          ),
        ),
      ],
    ),
  ],
)

private let approvedMusicLibrary = ApprovedMusicLibrary(
  schemaVersion: 2,
  revision: 7,
  generatedAt: snapshotDate,
  albums: [
    .init(
      id: "album-1",
      title: "Library Album",
      artistName: "Library Artist",
      artworkURL: URL(string: "https://example.com/album/600x600bb.jpg"),
      artwork: .init(
        url: "https://example.com/album/{w}x{h}bb.jpg",
        width: 1200,
        height: 1200,
        bgColor: "203040",
        textColor1: "ffffff",
        textColor2: "eeeeee",
        textColor3: "dddddd",
        textColor4: "cccccc",
      ),
      trackCount: 1,
      releaseDate: "2024-04-12",
      releaseType: "Album",
      addedAt: snapshotDate,
      tracks: [
        .init(
          id: "track-1",
          title: "Library Track",
          artistName: "Track Artist",
          albumID: "album-1",
          albumTitle: "Library Album",
          artworkURL: URL(string: "https://example.com/track.jpg"),
          durationInMillis: 180_000,
        ),
      ],
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
      releaseAlbumIds: ["album-1"],
      topSongs: [
        .init(
          id: "track-1",
          title: "Top Song",
          artistName: "Library Artist",
          albumID: "album-1",
          albumTitle: "Library Album",
          artworkURL: URL(string: "https://example.com/top-song.jpg"),
          durationInMillis: 200_000,
        ),
      ],
      addedAt: snapshotDate,
    ),
  ],
  playlists: [
    .init(
      id: .init(rawValue: UUID(3)),
      name: "Favorites",
      revision: 2,
      createdAt: snapshotDate,
      updatedAt: snapshotDate,
      entries: [
        .init(
          id: .init(rawValue: UUID(4)),
          track: .init(
            id: "track-1",
            title: "Library Track",
            artistName: "Track Artist",
            albumID: "album-1",
            albumTitle: "Library Album",
            artworkURL: URL(string: "https://example.com/track.jpg"),
            durationInMillis: 180_000,
          ),
        ),
      ],
    ),
  ],
)

private let v2ApprovedMusicLibraryJSON = #"""
{
  "schemaVersion": 2,
  "revision": 7,
  "generatedAt": "1970-01-01T00:16:40Z",
  "albums": [
    {
      "id": "album-1",
      "title": "Library Album",
      "artistName": "Library Artist",
      "artworkUrl": "https://example.com/album.jpg",
      "artwork": {
        "url": "https://example.com/album/{w}x{h}bb.jpg",
        "width": 1200,
        "height": 1200,
        "bgColor": "203040",
        "textColor1": "ffffff",
        "textColor2": "eeeeee",
        "textColor3": "dddddd",
        "textColor4": "cccccc"
      },
      "trackCount": 1,
      "releaseDate": "2024-04-12",
      "releaseType": "Album",
      "showsArtwork": true,
      "addedAt": "1970-01-01T00:16:40Z",
      "tracks": [{
        "id": "track-1",
        "title": "Library Track",
        "artistName": "Track Artist",
        "albumId": "album-1",
        "albumTitle": "Library Album",
        "artworkUrl": "https://example.com/track.jpg",
        "durationInMillis": 180000
      }]
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
      },
      "releaseAlbumIds": ["album-1"],
      "topSongs": [{
        "id": "track-1",
        "title": "Top Song",
        "artistName": "Library Artist",
        "albumId": "album-1",
        "albumTitle": "Library Album",
        "artworkUrl": "https://example.com/top-song.jpg",
        "durationInMillis": 200000
      }],
      "addedAt": "1970-01-01T00:16:40Z"
    }
  ],
  "playlists": [
    {
      "id": "00000000-0000-0000-0000-000000000003",
      "name": "Favorites",
      "revision": 2,
      "createdAt": "1970-01-01T00:16:40Z",
      "updatedAt": "1970-01-01T00:16:40Z",
      "entries": [
        {
          "id": "00000000-0000-0000-0000-000000000004",
          "track": {
            "id": "track-1",
            "title": "Library Track",
            "artistName": "Track Artist",
            "albumId": "album-1",
            "albumTitle": "Library Album",
            "artworkUrl": "https://example.com/track.jpg",
            "durationInMillis": 180000
          }
        }
      ]
    }
  ]
}
"""#
