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
    return .init(
      albums: albums.map { album in
        .init(
          id: album.appleMusicAlbumId.rawValue,
          title: album.title,
          artistName: album.artistName,
          artworkUrl: album.artworkUrl,
          trackCount: album.trackCount,
          showsArtwork: album.showsArtwork,
        )
      },
      artists: artists.map { artist in
        .init(
          id: artist.appleMusicArtistId.rawValue,
          name: artist.name,
          catalogMetadata: artist.catalogMetadata.map(MusicCatalogMetadata.init),
        )
      },
    )
  }
}

extension GetApprovedMusicAlbumTracks: Resolver {
  static func resolve(with input: Input, in ctx: MusicApp.InstallContext) async throws -> Output {
    try await requireMusicAccess(in: ctx)

    let album = try await Music.ApprovedAlbum.query()
      .where(.childId == ctx.child.id)
      .where(.appleMusicAlbumId == input.albumId)
      .first(in: ctx.db, orThrow: ctx.error(
        "f63d584c",
        .unauthorized,
        "Music album `\(input.albumId)` is not approved for this child",
      ))

    return await self.outputTracks(for: album)
  }

  private static func outputTracks(
    for album: Music.ApprovedAlbum,
  ) async -> [GetApprovedMusicLibrary.Output.Track] {
    do {
      let tracks = try await get(dependency: \.appleMusic).albumTracks(.init(
        albumId: album.appleMusicAlbumId,
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
        "Apple Music album tracks lookup failed for album `\(album.appleMusicAlbumId.rawValue)`: \(error)",
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
