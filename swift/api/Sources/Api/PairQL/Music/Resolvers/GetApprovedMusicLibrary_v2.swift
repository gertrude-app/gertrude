import DuetSQL
import Foundation
import MusicRoute

extension GetApprovedMusicLibrary_v2: Resolver {
  static func resolve(with input: Input, in ctx: MusicApp.InstallContext) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    if try await self.syncStorefront(input.storefront, in: ctx) {
      let refresh = Task {
        await MusicCatalogRefreshJob().exec(childIds: [ctx.child.id])
      }
      if ctx.env.mode == .test {
        _ = await refresh.value
      }
    }

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
      async let tracks = Music.ApprovedTrack.query()
        .where(.childId == ctx.child.id)
        .all(in: ctx.db)
      let (albumGrants, artistGrants, trackGrants) = try await (albums, artists, tracks)
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
        trackGrants: trackGrants.map {
          .init(
            appleMusicTrackId: $0.appleMusicTrackId,
            preferredAlbumId: $0.preferredAlbumId,
            createdAt: $0.createdAt,
            showsArtwork: $0.showsArtwork,
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
    async let trackCount = Music.ApprovedTrack.query()
      .where(.childId == ctx.child.id)
      .count(in: ctx.db)
    let grantCount = try await albumCount + artistCount + trackCount
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

  private static func syncStorefront(
    _ rawValue: String?,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Bool {
    guard let rawValue else { return false }
    let storefront = Music.Storefront(rawValue: rawValue.lowercased())
    guard storefront.isValid else {
      throw ctx.error(
        "2c9e5f95",
        .badRequest,
        "Invalid Apple Music storefront: `\(rawValue)`",
      )
    }
    guard storefront != ctx.child.appleMusicStorefront else { return false }
    var child = ctx.child
    child.appleMusicStorefront = storefront
    try await ctx.db.update(child)
    return true
  }
}
