import Dependencies
import DuetSQL
import MusicRoute
import Vapor

extension MusicApp {
  struct InstallContext: ResolverContext {
    let requestId: String
    let dashboardUrl: String
    let install: MusicApp.Install
    let device: IOSDevice
    let child: Child
    let telemetry: TelemetryBag

    @Dependency(\.db) var db
    @Dependency(\.env) var env
  }
}

private func requireMusicAccess(in ctx: MusicApp.InstallContext) async throws {
  let parent = try await ctx.child.parent(in: ctx.db)
  let account = try await parent.billingAccountSnapshot(
    in: ctx.db,
    at: get(dependency: \.date.now),
  )
  try requireGertrudeMusicAccess(in: ctx, billing: account)
}

private extension MusicCatalogMetadata {
  init(_ metadata: Music.CatalogMetadata) {
    self.init(
      artwork: metadata.artwork.map(MusicArtwork.init),
      editorialNotes: metadata.editorialNotes.map(MusicEditorialNotes.init),
      appleMusicUrl: metadata.appleMusicUrl,
      genreNames: metadata.genreNames,
    )
  }
}

private extension MusicArtwork {
  init(_ artwork: Music.Artwork) {
    self.init(
      url: artwork.url,
      width: artwork.width,
      height: artwork.height,
      bgColor: artwork.bgColor,
      textColor1: artwork.textColor1,
      textColor2: artwork.textColor2,
      textColor3: artwork.textColor3,
      textColor4: artwork.textColor4,
    )
  }
}

private extension MusicEditorialNotes {
  init(_ notes: Music.EditorialNotes) {
    self.init(
      tagline: notes.tagline,
      short: notes.short,
      standard: notes.standard,
      name: notes.name,
    )
  }
}

private struct ApprovedMusicAlbumSummary: Equatable, Sendable {
  var id: Music.AlbumId
  var artworkUrl: String?

  init(id: Music.AlbumId, artworkUrl: String?) {
    self.id = id
    self.artworkUrl = artworkUrl
  }

  init(album: Music.ApprovedAlbum) {
    self.init(id: album.appleMusicAlbumId, artworkUrl: album.artworkUrl)
  }

  init(album: AppleMusicCatalogAlbum) {
    self.init(id: album.id, artworkUrl: album.artworkUrl)
  }
}

extension AuthedRoute: RouteResponder {
  static func respond(to route: Self, in ctx: MusicApp.InstallContext) async throws -> Response {
    switch route {
    case .getApprovedMusicLibrary:
      let output = try await GetApprovedMusicLibrary.resolve(in: ctx)
      return try await self.respond(with: output)
    case .getApprovedMusicLibrary_v2:
      let output = try await GetApprovedMusicLibrary_v2.resolve(in: ctx)
      return try await self.respond(with: output)
    case .getApprovedMusicAlbumTracks(let input):
      let output = try await GetApprovedMusicAlbumTracks.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    }
  }
}

extension GetApprovedMusicLibrary_v2: NoInputResolver {
  static func resolve(in ctx: MusicApp.InstallContext) async throws -> Output {
    try await requireMusicAccess(in: ctx)

    let albums = try await self.hydrateArtworkIfNeeded(
      ctx.child.approvedMusicAlbums(in: ctx.db),
      in: ctx,
    )
    let artists = try await ctx.child.approvedMusicArtists(in: ctx.db)
    async let releaseAlbumsByArtistId = self.artistReleaseAlbumsByArtistId(for: artists)
    async let topSongsByArtistId = self.artistTopSongsByArtistId(for: artists)
    let artistReleaseAlbumsById = await releaseAlbumsByArtistId
    let artistTopSongsById = await topSongsByArtistId
    let artistReleaseAlbums = artists.flatMap {
      artistReleaseAlbumsById[$0.appleMusicArtistId] ?? []
    }
    return .init(
      albums: self.outputAlbums(
        explicitAlbums: albums,
        artistReleaseAlbums: artistReleaseAlbums,
      ),
      artists: artists.map { artist in
        .init(
          id: artist.appleMusicArtistId.rawValue,
          name: artist.name,
          catalogMetadata: artist.catalogMetadata.map(MusicCatalogMetadata.init),
          releaseAlbumIds: artistReleaseAlbumsById[artist.appleMusicArtistId]?
            .map(\.id.rawValue),
          topSongs: artistTopSongsById[artist.appleMusicArtistId]?.map { song in
            .init(
              id: song.id.rawValue,
              title: song.title,
              artistName: song.artistName,
              albumTitle: song.albumTitle,
              artworkUrl: song.artworkUrl,
              durationInMillis: song.durationInMillis,
            )
          },
        )
      },
    )
  }

  private static func outputAlbums(
    explicitAlbums: [Music.ApprovedAlbum],
    artistReleaseAlbums: [AppleMusicCatalogAlbum],
  ) -> [Output.Album] {
    var seenAlbumIds = Set<String>()
    var artistReleaseAlbumsById: [Music.AlbumId: AppleMusicCatalogAlbum] = [:]
    for album in artistReleaseAlbums where artistReleaseAlbumsById[album.id] == nil {
      artistReleaseAlbumsById[album.id] = album
    }
    var albums = explicitAlbums.map { album in
      _ = seenAlbumIds.insert(album.appleMusicAlbumId.rawValue)
      let catalogAlbum = artistReleaseAlbumsById[album.appleMusicAlbumId]
      return Output.Album(
        id: album.appleMusicAlbumId.rawValue,
        title: album.title,
        artistName: album.artistName,
        artworkUrl: album.artworkUrl,
        artwork: album.artwork.map(MusicArtwork.init),
        trackCount: album.trackCount ?? catalogAlbum?.trackCount,
        releaseDate: catalogAlbum?.releaseDate,
        releaseType: catalogAlbum?.releaseType,
        showsArtwork: album.showsArtwork,
      )
    }

    for album in artistReleaseAlbums {
      guard seenAlbumIds.insert(album.id.rawValue).inserted else { continue }
      albums.append(.init(
        id: album.id.rawValue,
        title: album.title,
        artistName: album.artistName,
        artworkUrl: album.artworkUrl,
        artwork: album.artwork.map(MusicArtwork.init),
        trackCount: album.trackCount,
        releaseDate: album.releaseDate,
        releaseType: album.releaseType,
        showsArtwork: true,
      ))
    }

    return albums
  }

  private static func hydrateArtworkIfNeeded(
    _ albums: [Music.ApprovedAlbum],
    in ctx: MusicApp.InstallContext,
  ) async -> [Music.ApprovedAlbum] {
    let missingAlbumIds = albums.compactMap { album in
      album.artwork == nil ? album.appleMusicAlbumId : nil
    }
    guard !missingAlbumIds.isEmpty else { return albums }

    let catalogAlbums: [AppleMusicCatalogAlbum]
    do {
      catalogAlbums = try await get(dependency: \.appleMusic).albums(.init(
        albumIds: missingAlbumIds,
        storefront: "us",
      ))
    } catch {
      with(dependency: \.logger).error(
        "Apple Music album artwork hydration failed for `\(missingAlbumIds.map(\.rawValue).joined(separator: ","))`: \(error)",
      )
      return albums
    }

    let catalogAlbumsById = Dictionary(uniqueKeysWithValues: catalogAlbums.map { ($0.id, $0) })
    var hydratedAlbums = albums
    for index in hydratedAlbums.indices where hydratedAlbums[index].artwork == nil {
      guard let catalogAlbum = catalogAlbumsById[hydratedAlbums[index].appleMusicAlbumId]
      else { continue }

      hydratedAlbums[index].artwork = catalogAlbum.artwork ?? .init(
        url: catalogAlbum.artworkUrl ?? hydratedAlbums[index].artworkUrl,
      )
      hydratedAlbums[index].artworkUrl = catalogAlbum.artworkUrl
        ?? hydratedAlbums[index].artworkUrl
      do {
        try await ctx.db.update(hydratedAlbums[index])
      } catch {
        with(dependency: \.logger).error(
          "Persisting Apple Music artwork failed for album `\(hydratedAlbums[index].appleMusicAlbumId.rawValue)`: \(error)",
        )
      }
    }
    return hydratedAlbums
  }

  fileprivate static func artistReleaseAlbums(
    for artists: [Music.ApprovedArtist],
  ) async -> [AppleMusicCatalogAlbum] {
    let albumsByArtistId = await self.artistReleaseAlbumsByArtistId(for: artists)
    return artists.flatMap { albumsByArtistId[$0.appleMusicArtistId] ?? [] }
  }

  private static func artistReleaseAlbumsByArtistId(
    for artists: [Music.ApprovedArtist],
  ) async -> [Music.ArtistId: [AppleMusicCatalogAlbum]] {
    let appleMusic = get(dependency: \.appleMusic)
    var albumsByArtistId: [Music.ArtistId: [AppleMusicCatalogAlbum]] = [:]
    for artist in artists {
      do {
        albumsByArtistId[artist.appleMusicArtistId] = try await appleMusic.artistAlbums(.init(
          artistId: artist.appleMusicArtistId,
          artistName: artist.name,
          storefront: "us",
        ))
      } catch {
        with(dependency: \.logger).error(
          "Apple Music artist albums lookup failed for artist `\(artist.appleMusicArtistId.rawValue)`: \(error)",
        )
      }
    }
    return albumsByArtistId
  }

  private static func artistTopSongsByArtistId(
    for artists: [Music.ApprovedArtist],
  ) async -> [Music.ArtistId: [AppleMusicCatalogTrack]] {
    let appleMusic = get(dependency: \.appleMusic)
    var topSongsByArtistId: [Music.ArtistId: [AppleMusicCatalogTrack]] = [:]
    for artist in artists {
      do {
        topSongsByArtistId[artist.appleMusicArtistId] = try await appleMusic.artistTopSongs(.init(
          artistId: artist.appleMusicArtistId,
          artistName: artist.name,
          storefront: "us",
        ))
      } catch {
        with(dependency: \.logger).error(
          "Apple Music artist top songs lookup failed for artist `\(artist.appleMusicArtistId.rawValue)`: \(error)",
        )
      }
    }
    return topSongsByArtistId
  }
}

extension GetApprovedMusicAlbumTracks: Resolver {
  static func resolve(with input: Input, in ctx: MusicApp.InstallContext) async throws -> Output {
    try await requireMusicAccess(in: ctx)

    let albumId = Music.AlbumId(rawValue: input.albumId)
    let explicitAlbums = try await Music.ApprovedAlbum.query()
      .where(.childId == ctx.child.id)
      .where(.appleMusicAlbumId == input.albumId)
      .all(in: ctx.db)
    if let explicitAlbum = explicitAlbums.first {
      return await self.outputTracks(for: ApprovedMusicAlbumSummary(album: explicitAlbum))
    }

    if let artistCoveredAlbum = try await self.artistCoveredAlbum(
      albumId: albumId,
      in: ctx,
    ) {
      return await self.outputTracks(for: artistCoveredAlbum)
    }

    throw ctx.error(
      "f63d584c",
      .unauthorized,
      "Music album `\(input.albumId)` is not approved for this child",
    )
  }

  private static func artistCoveredAlbum(
    albumId: Music.AlbumId,
    in ctx: MusicApp.InstallContext,
  ) async throws -> ApprovedMusicAlbumSummary? {
    let artists = try await ctx.child.approvedMusicArtists(in: ctx.db)
    let artistReleaseAlbums = await GetApprovedMusicLibrary_v2.artistReleaseAlbums(for: artists)
    return artistReleaseAlbums
      .first { $0.id == albumId }
      .map { ApprovedMusicAlbumSummary(album: $0) }
  }

  private static func outputTracks(
    for album: ApprovedMusicAlbumSummary,
  ) async -> [GetApprovedMusicLibrary.Output.Track] {
    do {
      let tracks = try await get(dependency: \.appleMusic).albumTracks(.init(
        albumId: album.id,
        storefront: "us",
      ))
      return tracks.map { track in
        .init(
          id: track.id.rawValue,
          title: track.title,
          artistName: track.artistName,
          artworkUrl: track.artworkUrl ?? album.artworkUrl,
        )
      }
    } catch {
      with(dependency: \.logger).error(
        "Apple Music album tracks lookup failed for album `\(album.id.rawValue)`: \(error)",
      )
      return []
    }
  }
}

extension GetApprovedMusicLibrary: NoInputResolver {
  static func resolve(in ctx: MusicApp.InstallContext) async throws -> Output {
    try await requireMusicAccess(in: ctx)

    let albums = try await ctx.child.approvedMusicAlbums(in: ctx.db)
    let tracksByAlbum = try await self.tracksByAlbum(for: albums)
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
  ) async throws -> [String: [AppleMusicCatalogTrack]] {
    let appleMusic = get(dependency: \.appleMusic)
    var tracksByAlbum: [String: [AppleMusicCatalogTrack]] = [:]
    for album in albums {
      do {
        tracksByAlbum[album.appleMusicAlbumId.rawValue] = try await appleMusic.albumTracks(.init(
          albumId: album.appleMusicAlbumId,
          storefront: "us",
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
