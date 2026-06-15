import Dependencies
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

extension AuthedRoute: RouteResponder {
  static func respond(to route: Self, in ctx: MusicApp.InstallContext) async throws -> Response {
    switch route {
    case .getApprovedMusicLibrary:
      let output = try await GetApprovedMusicLibrary.resolve(in: ctx)
      return try await self.respond(with: output)
    }
  }
}

extension GetApprovedMusicLibrary: NoInputResolver {
  static func resolve(in ctx: MusicApp.InstallContext) async throws -> Output {
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
        trackIds: tracks.map(\.id.rawValue),
      )
    }
    let outputTracks = albums.flatMap { album in
      (tracksByAlbum[album.appleMusicAlbumId.rawValue] ?? []).map { track in
        Output.Track(
          id: track.id.rawValue,
          title: track.title,
          artistName: track.artistName,
          albumId: album.appleMusicAlbumId.rawValue,
          albumTitle: track.albumTitle ?? album.title,
          artworkUrl: track.artworkUrl ?? album.artworkUrl,
          showsArtwork: album.showsArtwork,
        )
      }
    }
    return .init(albums: outputAlbums, tracks: outputTracks)
  }

  private static func tracksByAlbum(
    for albums: [Music.ApprovedAlbum],
  ) async throws -> [String: [AppleMusicCatalogTrack]] {
    let appleMusic = get(dependency: \.appleMusic)
    var tracksByAlbum: [String: [AppleMusicCatalogTrack]] = [:]
    for album in albums {
      tracksByAlbum[album.appleMusicAlbumId.rawValue] = try await appleMusic.albumTracks(.init(
        albumId: album.appleMusicAlbumId,
        storefront: "us",
      ))
    }
    return tracksByAlbum
  }
}
