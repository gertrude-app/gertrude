import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicStorefrontTests: ApiTestCase, @unchecked Sendable {
  func testChildStorefrontDefaultsToUS() async throws {
    let child = try await self.child()

    let stored = try await Child.query().where(.id == child.id).first(in: self.db)

    expect(Music.Storefront.default).toEqual("us")
    expect(child.model.appleMusicStorefront).toEqual("us")
    expect(stored.appleMusicStorefront).toEqual("us")
  }

  func testCatalogRequestPathsUseSuppliedStorefront() throws {
    let search = try appleMusicCatalogMixedSearchURL(.init(
      storefront: "de",
      term: "Die drei ??? Kids",
    ))
    let albumTracks = try appleMusicCatalogAlbumURL(.init(
      storefront: "de",
      albumId: "album-1",
    ))
    let artist = try appleMusicCatalogArtistResolutionURL("artist-1", storefront: "de")
    let albums = try appleMusicCatalogAlbumResolutionURL(
      ["album-1"],
      storefront: "de",
      requiringArtistRelationship: true,
    )
    let songs = try appleMusicCatalogSongsURL(["song-1"], storefront: "de")

    expect(search.path).toEqual("/v1/catalog/de/search")
    expect(albumTracks.path).toEqual("/v1/catalog/de/albums/album-1")
    expect(artist.path).toEqual("/v1/catalog/de/artists/artist-1")
    expect(albums.path).toEqual("/v1/catalog/de/albums")
    expect(songs.path).toEqual("/v1/catalog/de/songs")

    for malformed: Music.Storefront in ["", "US", "usa", "u", "../us"] {
      XCTAssertThrowsError(try appleMusicCatalogPath(malformed, "/search"))
    }
  }

  func testDashboardSearchUsesChildStorefront() async throws {
    let child = try await self.musicChild(with: { $0.appleMusicStorefront = "de" })
    let storefronts = LockIsolated<[Music.Storefront]>([])

    let output = try await withDependencies {
      $0.appleMusic.searchCatalog = { search in
        storefronts.withValue { $0.append(search.storefront) }
        return .init(items: [
          .artist(.init(id: "artist-1", name: "Die drei ??? Kids")),
        ])
      }
    } operation: {
      try await SearchMusicCatalog_v2.resolve(
        with: .init(childId: child.id, query: "Die drei ??? Kids", limit: nil),
        in: child.parent.context,
      )
    }

    expect(storefronts.value).toEqual(["de"])
    expect(output.items.compactMap(\.artist?.name)).toEqual(["Die drei ??? Kids"])
  }

  func testArtistApprovalUsesChildStorefront() async throws {
    let child = try await self.musicChild(with: { $0.appleMusicStorefront = "de" })
    let storefronts = LockIsolated<[Music.Storefront]>([])

    let output = try await withDependencies {
      $0.date.now = .reference
      $0.appleMusic.resolveArtist = { lookup in
        storefronts.withValue { $0.append(lookup.storefront) }
        return storefrontArtist(id: lookup.artistId, albumIds: ["album-1"])
      }
    } operation: {
      try await ApproveMusicArtist_v2.resolve(
        with: .init(childId: child.id, appleMusicArtistId: "artist-1"),
        in: child.parent.context,
      )
    }

    expect(storefronts.value).toEqual(["de"])
    expect(output.status).toEqual(.updated)
    expect(output.curation.artists.map(\.id)).toEqual(["artist-1"])
  }

  func testAlbumApprovalAndCurationUseChildStorefront() async throws {
    let child = try await self.musicChild(with: { $0.appleMusicStorefront = "de" })
    let album = storefrontAlbum(id: "album-1", trackIds: ["track-1", "track-2"])
    let storefronts = LockIsolated<[Music.Storefront]>([])

    let approved = try await withDependencies {
      $0.date.now = .reference
      $0.appleMusic.resolveAlbum = { lookup in
        storefronts.withValue { $0.append(lookup.storefront) }
        return album
      }
    } operation: {
      try await ApproveMusicAlbum_v2.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: album.id),
        in: child.parent.context,
      )
    }

    let curation = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { lookup in
        storefronts.withValue { $0.append(lookup.storefront) }
        return album
      }
    } operation: {
      try await GetMusicAlbumCuration.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: album.id),
        in: child.parent.context,
      )
    }

    let saved = try await withDependencies {
      $0.date.now = .reference + 200
      $0.appleMusic.resolveAlbum = { lookup in
        storefronts.withValue { $0.append(lookup.storefront) }
        return album
      }
    } operation: {
      try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: album.id,
          expectedRevision: curation.revision,
          selectedTrackIds: ["track-1"],
        ),
        in: child.parent.context,
      )
    }

    expect(storefronts.value).toEqual(["de", "de", "de"]) // approve, get, save
    expect(approved.albums.map(\.id)).toEqual(["album-1"])
    expect(curation.scope).toEqual(.wholeAlbum)
    expect(saved.status).toEqual(.updated)
    expect(saved.album.scope).toEqual(.selectedTracks)
  }

  func testCatalogRefreshResolvesEachChildInItsOwnStorefront() async throws {
    let german = try await self.child(with: { $0.appleMusicStorefront = "de" })
    let american = try await self.child()
    let germanAlbum = storefrontAlbum(id: "album-de", trackIds: ["track-de"])
    let americanAlbum = storefrontAlbum(id: "album-us", trackIds: ["track-us"])
    for (child, album) in [(german, germanAlbum), (american, americanAlbum)] {
      _ = try await self.db.create(Music.ApprovedAlbum(
        childId: child.id,
        appleMusicAlbumId: album.id,
        title: album.title,
        artistName: album.artistName,
        trackCount: album.trackCount,
        resolution: album,
        resolvedAt: .reference,
      ))
    }
    let lookups = LockIsolated<[AppleMusicAlbumResolutionLookup]>([])

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { lookup in
        lookups.withValue { $0.append(lookup) }
        return lookup.albumId == germanAlbum.id ? germanAlbum : americanAlbum
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [german.id, american.id])
    }

    expect(summary.failures).toEqual(0)
    expect(lookups.value.sorted { $0.albumId.rawValue < $1.albumId.rawValue }).toEqual([
      .init(storefront: "de", albumId: "album-de"),
      .init(storefront: "us", albumId: "album-us"),
    ])
  }
}

private func storefrontAlbum(
  id: Music.AlbumId,
  trackIds: [Music.TrackId],
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: "Album \(id.rawValue)",
    artistName: "Artist",
    artistIds: ["artist-1"],
    trackCount: trackIds.count,
    releaseType: "Album",
    tracks: trackIds.enumerated().map { index, trackId in
      .init(
        id: trackId,
        title: "Track \(index + 1)",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: id,
        albumTitle: "Album \(id.rawValue)",
        discNumber: 1,
        trackNumber: index + 1,
      )
    },
  )
}

private func storefrontArtist(
  id: Music.ArtistId,
  albumIds: [Music.AlbumId],
) -> Music.ResolvedArtist {
  .init(
    id: id,
    name: "Die drei ??? Kids",
    topSongs: [],
    albums: albumIds.map { storefrontAlbum(id: $0, trackIds: ["\($0.rawValue)-track"]) },
  )
}
