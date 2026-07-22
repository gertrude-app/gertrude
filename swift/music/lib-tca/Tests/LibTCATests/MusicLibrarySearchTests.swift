import CustomDump
import Foundation
import Testing

@testable import LibTCA

struct MusicLibrarySearchTests {
  @Test
  func normalizesCaseDiacriticsAndWordOrder() {
    let library = self.library()
    let search = MusicLibrarySearch(library: library)

    expectNoDifference(
      search.results(query: "BLUE cafe").map(\.id),
      [
        .album("album-blue"),
        .song("song-deja-vu"),
        .song("song-northern-light"),
      ],
    )
    expectNoDifference(
      search.results(query: "beyonce").map(\.id),
      [
        .artist("artist-beyonce"),
        .album("album-blue"),
        .song("song-deja-vu"),
        .song("song-northern-light"),
      ],
    )
  }

  @Test
  func ignoresOmittedPunctuation() {
    let album = ApprovedAlbum(
      id: "power-up",
      title: "Power Up",
      artistName: "AC/DC",
      tracks: [
        .init(
          id: "dont-stop",
          title: "Don’t Stop",
          artistName: "AC/DC",
        ),
      ],
    )
    let search = MusicLibrarySearch(library: .init(
      albums: [album],
      artists: [.init(id: "acdc", name: "AC/DC")],
    ))

    expectNoDifference(
      search.results(query: "acdc").map(\.id),
      [.artist("acdc"), .album("power-up"), .song("dont-stop")],
    )
    expectNoDifference(
      search.results(query: "dont").map(\.id),
      [.song("dont-stop")],
    )
  }

  @Test
  func requiresEveryWordAcrossEligibleFields() {
    let search = MusicLibrarySearch(library: self.library())

    expectNoDifference(
      search.results(query: "beyonce cafe").map(\.id),
      [
        .album("album-blue"),
        .song("song-deja-vu"),
        .song("song-northern-light"),
      ],
    )
    expectNoDifference(search.results(query: "beyonce missing"), [])
  }

  @Test
  func primaryMatchesRankBeforeRelatedMetadataMatches() {
    let album = ApprovedAlbum(
      id: "album-queen",
      title: "Queen II",
      artistName: "Queen",
      tracks: [
        .init(
          id: "song-killer-queen",
          title: "Killer Queen",
          artistName: "Queen",
        ),
        .init(
          id: "song-another",
          title: "Another One",
          artistName: "Queen",
        ),
      ],
    )
    let library = ApprovedMusicLibrary(
      albums: [album],
      artists: [.init(id: "artist-queen", name: "Queen")],
      playlists: [self.playlist(name: "Queen Favorites")],
    )

    expectNoDifference(
      MusicLibrarySearch(library: library).results(query: "queen").map(\.id),
      [
        .artist("artist-queen"),
        .song("song-killer-queen"),
        .playlist(self.playlistID),
        .album("album-queen"),
        .song("song-another"),
      ],
    )
  }

  @Test
  func returnsStrictTopThirty() {
    let playlists = (0 ..< 40).map { index in
      MusicPlaylist(
        id: .init(rawValue: UUID(index + 1)),
        name: "Mix \(index.formatted(.number.precision(.integerLength(2))))",
        revision: 1,
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0),
      )
    }
    let results = MusicLibrarySearch(
      library: ApprovedMusicLibrary(playlists: playlists),
    ).results(query: "mix")

    #expect(results.count == 30)
    expectNoDifference(
      results.map(\.id),
      playlists.prefix(30).map { .playlist($0.id) },
    )
  }

  @Test
  func deduplicatesSongsAndIgnoresPlaylistMembership() {
    let track = ApprovedTrack(
      id: "duplicate-song",
      title: "Only Once",
      artistName: "Artist",
    )
    let firstAlbum = ApprovedAlbum(
      id: "first-album",
      title: "First",
      artistName: "Artist",
      tracks: [track],
    )
    let secondAlbum = ApprovedAlbum(
      id: "second-album",
      title: "Second",
      artistName: "Artist",
      tracks: [track],
    )
    let playlist = MusicPlaylist(
      id: self.playlistID,
      name: "Unrelated Playlist",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 0),
      updatedAt: Date(timeIntervalSince1970: 0),
      entries: [
        .init(id: .init(rawValue: UUID(2)), track: track.withAlbumID(firstAlbum.id)),
      ],
    )
    let results = MusicLibrarySearch(library: .init(
      albums: [firstAlbum, secondAlbum],
      playlists: [playlist],
    )).results(query: "only once")

    expectNoDifference(results.map(\.id), [.song(track.id)])
    guard case .song(_, let albumID, _, _) = results.first?.source else {
      Issue.record("Expected a song result")
      return
    }
    #expect(albumID == firstAlbum.id)
  }

  private let playlistID = MusicPlaylist.ID(rawValue: UUID(1))

  private func library() -> ApprovedMusicLibrary {
    let album = ApprovedAlbum(
      id: "album-blue",
      title: "Café Blue",
      artistName: "Beyoncé Knowles",
      tracks: [
        .init(
          id: "song-deja-vu",
          title: "Déjà Vu",
          artistName: "Beyoncé Knowles",
          albumTitle: "Café Blue",
        ),
        .init(
          id: "song-northern-light",
          title: "Northern Light",
          artistName: "Beyoncé Knowles",
          albumTitle: "Café Blue",
        ),
      ],
    )
    return ApprovedMusicLibrary(
      albums: [album],
      artists: [.init(id: "artist-beyonce", name: "Beyoncé Knowles")],
      playlists: [self.playlist(name: "Night Drive")],
    )
  }

  private func playlist(name: String) -> MusicPlaylist {
    MusicPlaylist(
      id: self.playlistID,
      name: name,
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 0),
      updatedAt: Date(timeIntervalSince1970: 0),
    )
  }
}
