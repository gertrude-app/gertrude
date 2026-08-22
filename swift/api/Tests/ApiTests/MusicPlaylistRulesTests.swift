import Foundation
import MusicRoute
import XCTest
import XExpect

@testable import Api

final class MusicPlaylistRulesTests: XCTestCase {
  func testV2SnapshotContainsCompleteOrderedPlaylistEntries() {
    let index = Music.PlaylistRules.EffectiveTrackIndex(albums: [
      playlistAlbum(
        id: "album-1",
        tracks: [
          playlistTrack(id: "track-1", albumId: "album-1", title: "One"),
          playlistTrack(id: "track-2", albumId: "album-1", title: "Two"),
        ],
      ),
    ])
    let playlists = Music.PlaylistRules.compile(
      playlists: [
        .init(
          id: UUID(1),
          name: "Favorites",
          revision: 3,
          createdAt: .reference,
          updatedAt: .reference + 10,
          entries: [
            .init(id: UUID(3), trackId: "track-2", preferredAlbumId: "album-1"),
            .init(id: UUID(2), trackId: "track-1", preferredAlbumId: "album-1"),
            .init(id: UUID(4), trackId: "track-2", preferredAlbumId: "album-1"),
          ],
        ),
      ],
      using: index,
    )
    let snapshot = playlistCatalogSnapshot(
      albums: index.albums,
      playlists: playlists,
    )

    expect(snapshot.schemaVersion).toEqual(2)
    expect(snapshot.revision).toEqual(7)
    expect(snapshot.playlists).toEqual([
      .init(
        id: UUID(1),
        name: "Favorites",
        revision: 3,
        createdAt: .reference,
        updatedAt: .reference + 10,
        entries: [
          .init(
            id: UUID(3),
            track: playlistTrack(id: "track-2", albumId: "album-1", title: "Two"),
          ),
          .init(
            id: UUID(2),
            track: playlistTrack(id: "track-1", albumId: "album-1", title: "One"),
          ),
          .init(
            id: UUID(4),
            track: playlistTrack(id: "track-2", albumId: "album-1", title: "Two"),
          ),
        ],
      ),
    ])
  }

  func testDuplicateMutationOutputRoundTripsAuthoritativeSnapshot() throws {
    let snapshot = playlistCatalogSnapshot(albums: [])
    let output = MusicPlaylistMutationOutput.duplicateConfirmationRequired(
      snapshot: snapshot,
      confirmation: .track(
        playlistId: UUID(1),
        duplicate: .init(trackId: "track-1", title: "Track", existingCount: 2),
      ),
    )

    let data = try JSONEncoder().encode(output)
    let decoded = try JSONDecoder().decode(MusicPlaylistMutationOutput.self, from: data)

    expect(decoded).toEqual(output)
  }

  func testBatchDuplicateMutationOutputRoundTripsAuthoritativeSnapshot() throws {
    let snapshot = playlistCatalogSnapshot(albums: [])
    let output = MusicPlaylistMutationOutput.batchDuplicateConfirmationRequired(
      snapshot: snapshot,
      confirmation: .init(
        playlistId: UUID(1),
        duplicates: [.init(trackId: "track-1", title: "Track", existingCount: 2)],
      ),
    )

    let data = try JSONEncoder().encode(output)
    let decoded = try JSONDecoder().decode(MusicPlaylistMutationOutput.self, from: data)

    expect(decoded).toEqual(output)
  }

  func testSnapshotWithoutPlaylistFieldDecodesAsEmpty() throws {
    let snapshot = playlistCatalogSnapshot(albums: [])
    let encoded = try JSONEncoder().encode(snapshot)
    var object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: encoded) as? [String: Any],
    )
    object["playlists"] = nil
    let legacyData = try JSONSerialization.data(withJSONObject: object)

    let decoded = try JSONDecoder().decode(MusicLibrarySnapshot.self, from: legacyData)

    expect(decoded.playlists).toEqual([])
  }

  func testTrackSelectionRequiresExactCurrentAlbumCoverage() throws {
    let index = Music.PlaylistRules.EffectiveTrackIndex(albums: [
      playlistAlbum(
        id: "album-1",
        tracks: [playlistTrack(id: "track-1", albumId: "album-1")],
      ),
    ])
    let playlist = emptyPlaylist()

    let plan = try Music.PlaylistRules.planAddition(
      selection: .track(trackId: "track-1", albumId: "album-1"),
      duplicateResolution: .requestConfirmation,
      to: playlist,
      using: index,
    )

    expect(plan).toEqual(.append([
      .init(trackId: "track-1", preferredAlbumId: "album-1"),
    ]))
    XCTAssertThrowsError(try Music.PlaylistRules.planAddition(
      selection: .track(trackId: "track-1", albumId: "album-2"),
      duplicateResolution: .requestConfirmation,
      to: playlist,
      using: index,
    )) { error in
      expect(error as? Music.PlaylistRules.RuleError).toEqual(
        .unauthorizedTrack(trackId: "track-1", albumId: "album-2"),
      )
    }
    XCTAssertThrowsError(try Music.PlaylistRules.planAddition(
      selection: .album(albumId: "album-2"),
      duplicateResolution: .requestConfirmation,
      to: playlist,
      using: index,
    )) { error in
      expect(error as? Music.PlaylistRules.RuleError).toEqual(
        .unauthorizedAlbum("album-2"),
      )
    }
  }

  func testOverlapRetainsEntryAndFallsBackFromPreferredAlbum() {
    let entry = Music.PlaylistRules.Entry(
      id: UUID(2),
      trackId: "shared-track",
      preferredAlbumId: "album-1",
    )
    let firstTrack = playlistTrack(
      id: "shared-track",
      albumId: "album-1",
      title: "Preferred",
    )
    let overlappingTrack = playlistTrack(
      id: "shared-track",
      albumId: "album-2",
      title: "Still Approved",
    )
    let overlappingIndex = Music.PlaylistRules.EffectiveTrackIndex(albums: [
      playlistAlbum(id: "album-1", tracks: [firstTrack]),
      playlistAlbum(id: "album-2", tracks: [overlappingTrack]),
    ])
    let fallbackIndex = Music.PlaylistRules.EffectiveTrackIndex(albums: [
      playlistAlbum(id: "album-2", tracks: [overlappingTrack]),
    ])
    let revokedIndex = Music.PlaylistRules.EffectiveTrackIndex(albums: [])

    let overlapping = Music.PlaylistRules.reconcile(entries: [entry], using: overlappingIndex)
    let fallback = Music.PlaylistRules.reconcile(entries: [entry], using: fallbackIndex)
    let revoked = Music.PlaylistRules.reconcile(entries: [entry], using: revokedIndex)

    expect(overlapping.entries.map(\.track)).toEqual([firstTrack])
    expect(overlapping.removedEntryIds).toEqual([])
    expect(fallback.entries.map(\.track)).toEqual([overlappingTrack])
    expect(fallback.removedEntryIds).toEqual([])
    expect(revoked.entries).toEqual([])
    expect(revoked.removedEntryIds).toEqual([UUID(2)])
  }

  func testFinalRevocationPreservesEmptyPlaylist() {
    let playlist = Music.PlaylistRules.Playlist(
      id: UUID(1),
      name: "Keep Me",
      revision: 2,
      createdAt: .reference,
      updatedAt: .reference,
      entries: [
        .init(id: UUID(2), trackId: "revoked", preferredAlbumId: "album-1"),
      ],
    )

    let output = Music.PlaylistRules.compile(
      playlists: [playlist],
      using: .init(albums: []),
    )

    expect(output).toEqual([
      .init(
        id: UUID(1),
        name: "Keep Me",
        revision: 2,
        createdAt: .reference,
        updatedAt: .reference,
        entries: [],
      ),
    ])
  }

  func testIndividualDuplicateRequiresStructuredConfirmationAndCanAddAgain() throws {
    let track = playlistTrack(id: "track-1", albumId: "album-1", title: "Repeat Me")
    let index = Music.PlaylistRules.EffectiveTrackIndex(albums: [
      playlistAlbum(id: "album-1", tracks: [track]),
    ])
    let playlist = Music.PlaylistRules.Playlist(
      id: UUID(1),
      name: "Favorites",
      revision: 1,
      createdAt: .reference,
      updatedAt: .reference,
      entries: [
        .init(id: UUID(2), trackId: "track-1", preferredAlbumId: "album-1"),
        .init(id: UUID(3), trackId: "track-1", preferredAlbumId: "album-1"),
      ],
    )
    let selection = MusicPlaylistSourceSelection.track(
      trackId: "track-1",
      albumId: "album-1",
    )

    let confirmation = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .requestConfirmation,
      to: playlist,
      using: index,
    )
    let append = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .addAgain,
      to: playlist,
      using: index,
    )

    expect(confirmation).toEqual(.confirmationRequired(.track(
      playlistId: UUID(1),
      duplicate: .init(trackId: "track-1", title: "Repeat Me", existingCount: 2),
    )))
    expect(append).toEqual(.append([
      .init(trackId: "track-1", preferredAlbumId: "album-1"),
    ]))
  }

  func testWholeAlbumDuplicatePoliciesPreserveSourceOrder() throws {
    let tracks = [
      playlistTrack(id: "track-1", albumId: "album-1", title: "One"),
      playlistTrack(id: "track-2", albumId: "album-1", title: "Two"),
      playlistTrack(id: "track-3", albumId: "album-1", title: "Three"),
    ]
    let index = Music.PlaylistRules.EffectiveTrackIndex(albums: [
      playlistAlbum(id: "album-1", tracks: tracks),
    ])
    let playlist = Music.PlaylistRules.Playlist(
      id: UUID(1),
      name: "Favorites",
      revision: 1,
      createdAt: .reference,
      updatedAt: .reference,
      entries: [
        .init(id: UUID(2), trackId: "track-2", preferredAlbumId: "album-1"),
      ],
    )
    let selection = MusicPlaylistSourceSelection.album(albumId: "album-1")

    let confirmation = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .requestConfirmation,
      to: playlist,
      using: index,
    )
    let addAll = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .addAll,
      to: playlist,
      using: index,
    )
    let addOnlyNew = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .addOnlyNew,
      to: playlist,
      using: index,
    )

    expect(confirmation).toEqual(.confirmationRequired(.album(
      playlistId: UUID(1),
      albumId: "album-1",
      duplicates: [
        .init(trackId: "track-2", title: "Two", existingCount: 1),
      ],
    )))
    expect(addAll).toEqual(.append([
      .init(trackId: "track-1", preferredAlbumId: "album-1"),
      .init(trackId: "track-2", preferredAlbumId: "album-1"),
      .init(trackId: "track-3", preferredAlbumId: "album-1"),
    ]))
    expect(addOnlyNew).toEqual(.append([
      .init(trackId: "track-1", preferredAlbumId: "album-1"),
      .init(trackId: "track-3", preferredAlbumId: "album-1"),
    ]))
  }

  func testArtistSelectionUsesNewestFirstDeduplicatedDiscography() throws {
    let repeatedTrack = playlistTrack(id: "shared", albumId: "newest", title: "Shared")
    let newestAlbum = playlistAlbum(
      id: "newest",
      releaseDate: "2025-06-01",
      tracks: [
        playlistTrack(id: "newest-first", albumId: "newest", title: "Newest"),
        repeatedTrack,
      ],
    )
    let olderAlbum = playlistAlbum(
      id: "older",
      releaseDate: "2020-03-01",
      tracks: [
        playlistTrack(id: "older-first", albumId: "older", title: "Older"),
        playlistTrack(id: "shared", albumId: "older", title: "Shared"),
      ],
    )
    let artist = MusicLibrarySnapshot.Artist(
      id: "artist-1",
      name: "Artist",
      releaseAlbumIds: [olderAlbum.id, newestAlbum.id],
      topSongs: [],
      addedAt: .reference,
    )
    let index = Music.PlaylistRules.EffectiveTrackIndex(
      albums: [olderAlbum, newestAlbum],
      artists: [artist],
    )

    let plan = try Music.PlaylistRules.planAddition(
      selection: .artist(artistId: artist.id),
      duplicateResolution: .requestConfirmation,
      to: emptyPlaylist(),
      using: index,
    )

    expect(plan).toEqual(.append([
      .init(trackId: "newest-first", preferredAlbumId: "newest"),
      .init(trackId: "shared", preferredAlbumId: "newest"),
      .init(trackId: "older-first", preferredAlbumId: "older"),
    ]))

    var playlist = emptyPlaylist()
    playlist.entries = [
      .init(id: UUID(2), trackId: "shared", preferredAlbumId: "newest"),
    ]
    let confirmation = try Music.PlaylistRules.planAddition(
      selection: .artist(artistId: artist.id),
      duplicateResolution: .requestConfirmation,
      to: playlist,
      using: index,
    )
    let addOnlyNew = try Music.PlaylistRules.planAddition(
      selection: .artist(artistId: artist.id),
      duplicateResolution: .addOnlyNew,
      to: playlist,
      using: index,
    )
    expect(confirmation).toEqual(.confirmationRequired(.artist(
      playlistId: playlist.id,
      artistId: artist.id,
      duplicates: [.init(trackId: "shared", title: "Shared", existingCount: 1)],
    )))
    expect(addOnlyNew).toEqual(.append([
      .init(trackId: "newest-first", preferredAlbumId: "newest"),
      .init(trackId: "older-first", preferredAlbumId: "older"),
    ]))

    XCTAssertThrowsError(try Music.PlaylistRules.planAddition(
      selection: .artist(artistId: "artist-2"),
      duplicateResolution: .requestConfirmation,
      to: emptyPlaylist(),
      using: index,
    )) { error in
      expect(error as? Music.PlaylistRules.RuleError).toEqual(
        .unauthorizedArtist("artist-2"),
      )
    }
  }

  func testPlaylistSelectionPreservesSourceOrderAndDuplicatePolicies() throws {
    let tracks = [
      playlistTrack(id: "track-1", albumId: "album-1", title: "One"),
      playlistTrack(id: "track-2", albumId: "album-1", title: "Two"),
    ]
    let source = Music.PlaylistRules.Playlist(
      id: UUID(2),
      name: "Source",
      revision: 1,
      createdAt: .reference,
      updatedAt: .reference,
      entries: [
        .init(id: UUID(3), trackId: "track-2", preferredAlbumId: "album-1"),
        .init(id: UUID(4), trackId: "track-1", preferredAlbumId: "album-1"),
        .init(id: UUID(5), trackId: "track-2", preferredAlbumId: "album-1"),
      ],
    )
    let index = Music.PlaylistRules.EffectiveTrackIndex(
      albums: [playlistAlbum(id: "album-1", tracks: tracks)],
      playlists: [source],
    )
    let selection = MusicPlaylistSourceSelection.playlist(playlistId: source.id)

    let append = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .requestConfirmation,
      to: emptyPlaylist(),
      using: index,
    )
    expect(append).toEqual(.append([
      .init(trackId: "track-2", preferredAlbumId: "album-1"),
      .init(trackId: "track-1", preferredAlbumId: "album-1"),
      .init(trackId: "track-2", preferredAlbumId: "album-1"),
    ]))

    var destination = emptyPlaylist()
    destination.entries = [
      .init(id: UUID(6), trackId: "track-2", preferredAlbumId: "album-1"),
    ]
    let confirmation = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .requestConfirmation,
      to: destination,
      using: index,
    )
    let addOnlyNew = try Music.PlaylistRules.planAddition(
      selection: selection,
      duplicateResolution: .addOnlyNew,
      to: destination,
      using: index,
    )
    expect(confirmation).toEqual(.confirmationRequired(.playlist(
      playlistId: destination.id,
      sourcePlaylistId: source.id,
      duplicates: [
        .init(trackId: "track-2", title: "Two", existingCount: 1),
        .init(trackId: "track-2", title: "Two", existingCount: 1),
      ],
    )))
    expect(addOnlyNew).toEqual(.append([
      .init(trackId: "track-1", preferredAlbumId: "album-1"),
    ]))

    XCTAssertThrowsError(try Music.PlaylistRules.planAddition(
      selection: .playlist(playlistId: UUID(7)),
      duplicateResolution: .requestConfirmation,
      to: destination,
      using: index,
    )) { error in
      expect(error as? Music.PlaylistRules.RuleError).toEqual(
        .unauthorizedPlaylist(UUID(7)),
      )
    }
  }

  func testDuplicateResolutionMustMatchSelectionKind() {
    let index = Music.PlaylistRules.EffectiveTrackIndex(albums: [
      playlistAlbum(
        id: "album-1",
        tracks: [playlistTrack(id: "track-1", albumId: "album-1")],
      ),
    ])

    XCTAssertThrowsError(try Music.PlaylistRules.planAddition(
      selection: .track(trackId: "track-1", albumId: "album-1"),
      duplicateResolution: .addAll,
      to: emptyPlaylist(),
      using: index,
    )) { error in
      expect(error as? Music.PlaylistRules.RuleError).toEqual(
        .invalidDuplicateResolution(.addAll),
      )
    }
    XCTAssertThrowsError(try Music.PlaylistRules.planAddition(
      selection: .album(albumId: "album-1"),
      duplicateResolution: .addAgain,
      to: emptyPlaylist(),
      using: index,
    )) { error in
      expect(error as? Music.PlaylistRules.RuleError).toEqual(
        .invalidDuplicateResolution(.addAgain),
      )
    }
  }

  func testPlaylistOrderIsDeterministic() {
    let older = Music.PlaylistRules.Playlist(
      id: UUID(3),
      name: "Older",
      revision: 1,
      createdAt: .reference,
      updatedAt: .reference,
      entries: [],
    )
    let sameDateLowerId = Music.PlaylistRules.Playlist(
      id: UUID(1),
      name: "Lower",
      revision: 1,
      createdAt: .reference + 10,
      updatedAt: .reference + 10,
      entries: [],
    )
    let sameDateHigherId = Music.PlaylistRules.Playlist(
      id: UUID(2),
      name: "Higher",
      revision: 1,
      createdAt: .reference + 10,
      updatedAt: .reference + 10,
      entries: [],
    )

    let output = Music.PlaylistRules.compile(
      playlists: [sameDateHigherId, older, sameDateLowerId],
      using: .init(albums: []),
    )

    expect(output.map(\.id)).toEqual([UUID(3), UUID(1), UUID(2)])
  }
}

private func emptyPlaylist() -> Music.PlaylistRules.Playlist {
  .init(
    id: UUID(1),
    name: "Favorites",
    revision: 1,
    createdAt: .reference,
    updatedAt: .reference,
    entries: [],
  )
}

private func playlistCatalogSnapshot(
  albums: [MusicLibrarySnapshot.Album],
  playlists: [MusicLibrarySnapshot.Playlist] = [],
) -> MusicLibrarySnapshot {
  .init(
    revision: 7,
    generatedAt: .reference,
    albums: albums,
    artists: [],
    playlists: playlists,
  )
}

private func playlistAlbum(
  id: String,
  title: String = "Album",
  releaseDate: String? = nil,
  tracks: [MusicLibrarySnapshot.Track],
) -> MusicLibrarySnapshot.Album {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    trackCount: tracks.count,
    releaseDate: releaseDate,
    showsArtwork: true,
    addedAt: .reference,
    tracks: tracks,
  )
}

private func playlistTrack(
  id: String,
  albumId: String,
  title: String = "Track",
) -> MusicLibrarySnapshot.Track {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    albumId: albumId,
    albumTitle: "Album",
    artworkUrl: "https://example.com/\(id).jpg",
    durationInMillis: 180_000,
  )
}
