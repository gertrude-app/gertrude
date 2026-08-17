import Dependencies
import MusicRoute

extension GetApprovedMusicLibrary: NoInputResolver {
  static func resolve(in ctx: MusicApp.InstallContext) async throws -> Output {
    await ctx.db.logDeprecated("GetApprovedMusicLibrary(v1)")
    try await requireMusicAccess(in: ctx)

    if let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: ctx.child.id,
      in: ctx.db,
    ) {
      return .init(albums: snapshot.payload.albums.map { album in
        .init(
          id: album.id,
          title: album.title,
          artistName: album.artistName,
          artworkUrl: album.artworkUrl,
          trackCount: album.trackCount,
          showsArtwork: album.showsArtwork,
          tracks: album.tracks.map { track in
            .init(
              id: track.id,
              title: track.title,
              artistName: track.artistName,
              artworkUrl: track.artworkUrl,
            )
          },
        )
      })
    }

    let albums = try await ctx.child.approvedMusicAlbums(in: ctx.db)
    let tracksByAlbum = try await self.tracksByAlbum(for: albums, ctx.child.appleMusicStorefront)
    let outputAlbums = albums.map { album in
      let tracks = tracksByAlbum[album.appleMusicAlbumId.rawValue] ?? []
      return Output.Album(
        id: album.appleMusicAlbumId.rawValue,
        title: album.title,
        artistName: album.artistName,
        artworkUrl: album.artworkUrl,
        trackCount: album.trackCount,
        showsArtwork: album.showsArtwork,
        tracks: tracks.map { track in
          Output.Track(
            id: track.id.rawValue,
            title: track.title,
            artistName: track.artistName,
            artworkUrl: track.artworkUrl ?? album.artworkUrl,
          )
        },
      )
    }
    return .init(albums: outputAlbums)
  }

  private static func tracksByAlbum(
    for albums: [Music.ApprovedAlbum],
    _ storefront: Music.Storefront,
  ) async throws -> [String: [AppleMusicCatalogTrack]] {
    let appleMusic = get(dependency: \.appleMusic)
    var tracksByAlbum: [String: [AppleMusicCatalogTrack]] = [:]
    for album in albums {
      do {
        tracksByAlbum[album.appleMusicAlbumId.rawValue] = try await appleMusic.albumTracks(.init(
          storefront: storefront,
          albumId: album.appleMusicAlbumId,
        ))
      } catch {
        with(dependency: \.logger).error(
          "Apple Music album tracks lookup failed for album `\(album.appleMusicAlbumId.rawValue)`: \(error)",
        )
        tracksByAlbum[album.appleMusicAlbumId.rawValue] = []
      }
    }
    return tracksByAlbum
  }
}
