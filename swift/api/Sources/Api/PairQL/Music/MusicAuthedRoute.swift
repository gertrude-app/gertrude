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

    let albums = try await ctx.child.approvedMusicAlbums(in: ctx.db)
    let artists = try await ctx.child.approvedMusicArtists(in: ctx.db)
    let artistReleaseAlbums = await self.artistReleaseAlbums(for: artists)
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
        )
      },
    )
  }

  private static func outputAlbums(
    explicitAlbums: [Music.ApprovedAlbum],
    artistReleaseAlbums: [AppleMusicCatalogAlbum],
  ) -> [Output.Album] {
    var seenAlbumIds = Set<String>()
    var albums = explicitAlbums.map { album in
      _ = seenAlbumIds.insert(album.appleMusicAlbumId.rawValue)
      return Output.Album(
        id: album.appleMusicAlbumId.rawValue,
        title: album.title,
        artistName: album.artistName,
        artworkUrl: album.artworkUrl,
        trackCount: album.trackCount,
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
        trackCount: album.trackCount,
        showsArtwork: true,
      ))
    }

    return albums
  }

  fileprivate static func artistReleaseAlbums(
    for artists: [Music.ApprovedArtist],
  ) async -> [AppleMusicCatalogAlbum] {
    let appleMusic = get(dependency: \.appleMusic)
    var albums: [AppleMusicCatalogAlbum] = []
    for artist in artists {
      do {
        let artistAlbums = try await appleMusic.artistAlbums(.init(
          artistId: artist.appleMusicArtistId,
          artistName: artist.name,
          storefront: "us",
        ))
        albums.append(contentsOf: artistAlbums)
      } catch {
        with(dependency: \.logger).error(
          "Apple Music artist albums lookup failed for artist `\(artist.appleMusicArtistId.rawValue)`: \(error)",
        )
      }
    }
    return albums
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
