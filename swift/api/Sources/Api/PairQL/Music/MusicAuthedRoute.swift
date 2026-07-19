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

func requireMusicAccess(in ctx: MusicApp.InstallContext) async throws {
  let parent = try await ctx.child.parent(in: ctx.db)
  let account = try await parent.billingAccountSnapshot(
    in: ctx.db,
    at: get(dependency: \.date.now),
  )
  try requireGertrudeMusicAccess(in: ctx, billing: account)
}

extension AuthedRoute: RouteResponder {
  static func respond(to route: Self, in ctx: MusicApp.InstallContext) async throws -> Response {
    switch route {
    case .getApprovedMusicLibrary:
      let output = try await GetApprovedMusicLibrary.resolve(in: ctx)
      return try await self.respond(with: output)
    case .getApprovedMusicLibrary_v2(let input):
      let output = try await GetApprovedMusicLibrary_v2.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .createMusicPlaylist(let input):
      let output = try await CreateMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .renameMusicPlaylist(let input):
      let output = try await RenameMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .deleteMusicPlaylist(let input):
      let output = try await DeleteMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .addToMusicPlaylist(let input):
      let output = try await AddToMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .removeMusicPlaylistEntry(let input):
      let output = try await RemoveMusicPlaylistEntry.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .reorderMusicPlaylistEntries(let input):
      let output = try await ReorderMusicPlaylistEntries.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    }
  }
}

extension GetApprovedMusicLibrary_v2: Resolver {
  static func resolve(with input: Input, in ctx: MusicApp.InstallContext) async throws -> Output {
    try await requireMusicAccess(in: ctx)

    if let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: ctx.child.id,
      in: ctx.db,
    ) {
      async let albums = Music.ApprovedAlbum.query()
        .where(.childId == ctx.child.id)
        .all(in: ctx.db)
      async let artists = Music.ApprovedArtist.query()
        .where(.childId == ctx.child.id)
        .all(in: ctx.db)
      let (albumGrants, artistGrants) = try await (albums, artists)
      guard albumGrants.allSatisfy({ $0.resolution != nil }),
            artistGrants.allSatisfy({ $0.resolution != nil }) else {
        throw ctx.error(
          "6cfffc06",
          .serverError,
          "Music grants are unresolved for child `\(ctx.child.id)`",
        )
      }
      guard snapshot.revision == snapshot.payload.revision else {
        throw ctx.error(
          "03dbe342",
          .serverError,
          "Music snapshot revision mismatch for child `\(ctx.child.id)`",
        )
      }
      var content = try Music.LibrarySnapshotCompiler.compile(
        albumGrants: albumGrants.map {
          .init(
            appleMusicAlbumId: $0.appleMusicAlbumId,
            createdAt: $0.createdAt,
            showsArtwork: $0.showsArtwork,
            resolution: $0.resolution,
          )
        },
        artistGrants: artistGrants.map {
          .init(
            appleMusicArtistId: $0.appleMusicArtistId,
            createdAt: $0.createdAt,
            resolution: $0.resolution,
          )
        },
      )
      let index = Music.PlaylistRules.EffectiveTrackIndex(albums: content.albums)
      let playlists = try await Music.PlaylistRepository.rulesPlaylists(
        for: ctx.child.id,
        in: ctx.db,
      )
      content.playlists = Music.PlaylistRules.compile(playlists: playlists, using: index)
      guard snapshot.payload.hasSameContent(as: content) else {
        throw ctx.error(
          "4d4bdeee",
          .serverError,
          "Music snapshot content mismatch for child `\(ctx.child.id)`",
        )
      }
      if input.knownRevision == snapshot.revision {
        return .unchanged(revision: snapshot.revision)
      }
      return .snapshot(snapshot.payload)
    }

    async let albumCount = Music.ApprovedAlbum.query()
      .where(.childId == ctx.child.id)
      .count(in: ctx.db)
    async let artistCount = Music.ApprovedArtist.query()
      .where(.childId == ctx.child.id)
      .count(in: ctx.db)
    let grantCount = try await albumCount + artistCount
    guard grantCount == 0 else {
      throw ctx.error(
        "c5475ffa",
        .serverError,
        "Music grants exist without a published snapshot for child `\(ctx.child.id)`",
      )
    }

    let empty = MusicLibrarySnapshot(
      revision: 0,
      generatedAt: .init(timeIntervalSince1970: 0),
      albums: [],
      artists: [],
    )
    if input.knownRevision == 0 {
      return .unchanged(revision: 0)
    }
    return .snapshot(empty)
  }
}

extension GetApprovedMusicLibrary: NoInputResolver {
  static func resolve(in ctx: MusicApp.InstallContext) async throws -> Output {
    try await requireMusicAccess(in: ctx)

    let albums = try await ctx.child.approvedMusicAlbums(in: ctx.db)
    if let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: ctx.child.id,
      in: ctx.db,
    ) {
      let snapshotAlbumsById = Dictionary(
        uniqueKeysWithValues: snapshot.payload.albums.map { ($0.id, $0) },
      )
      return .init(albums: albums.compactMap { approved in
        guard let album = snapshotAlbumsById[approved.appleMusicAlbumId.rawValue] else {
          return nil
        }
        return .init(
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
