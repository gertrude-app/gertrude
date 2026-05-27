import Testing

@testable import LibTCA

@MainActor
struct ApprovedMusicClientTests {
  @Test
  func mockLibraryIsUsable() async throws {
    let library = try await ApprovedMusicClient.mock.loadApprovedLibrary()

    #expect(!library.isEmpty)
    #expect(!library.tracks.isEmpty)
    #expect(Set(library.albums.map(\.id)).count == library.albums.count)
    #expect(Set(library.artists.map(\.id)).count == library.artists.count)
    #expect(Set(library.tracks.map(\.id)).count == library.tracks.count)

    let albumIDs = Set(library.albums.map(\.id))
    let artistIDs = Set(library.artists.map(\.id))
    let trackIDs = Set(library.tracks.map(\.id))

    for album in library.albums {
      #expect(!album.trackIDs.isEmpty)
      #expect(Set(album.trackIDs).isSubset(of: trackIDs))

      #expect(library.tracks(for: album).map(\.id) == album.trackIDs)

      for trackID in album.trackIDs {
        #expect(library.track(id: trackID)?.albumID == album.id)
      }
    }

    for artist in library.artists {
      #expect(!artist.albumIDs.isEmpty || !artist.trackIDs.isEmpty)
      #expect(Set(artist.albumIDs).isSubset(of: albumIDs))
      #expect(Set(artist.trackIDs).isSubset(of: trackIDs))

      for trackID in artist.trackIDs {
        #expect(library.track(id: trackID)?.artistIDs.contains(artist.id) == true)
      }
    }

    for track in library.tracks {
      #expect(!track.artistIDs.isEmpty)
      #expect(Set(track.artistIDs).isSubset(of: artistIDs))
      if let albumID = track.albumID {
        #expect(albumIDs.contains(albumID))
      }
    }
  }

  @Test
  func emptyLibraryIsAvailableForTestsAndPreviews() async throws {
    let library = try await ApprovedMusicClient.empty.loadApprovedLibrary()

    #expect(library.isEmpty)
  }
}
