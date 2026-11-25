import Dependencies
import PairQL

struct GetMusicAlbumCuration: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicAlbumId: Music.AlbumId
  }

  typealias Output = MusicAlbumCuration
}

extension GetMusicAlbumCuration: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let catalogAlbum = try await resolveMusicCurationCatalogAlbum(
      input.appleMusicAlbumId,
      for: child,
    )
    let policy = try await Music.CatalogPolicy.load(childId: child.id, in: context.db)
    let source = try policy.albumCurationSource(
      input.appleMusicAlbumId,
      catalogAlbum: catalogAlbum,
    )
    let revision = try await musicCurationRevision(
      childId: child.id,
      policy: policy,
      in: context.db,
      context: context,
    )
    return policy.albumCuration(source, revision: revision)
  }
}

func resolveMusicCurationCatalogAlbum(
  _ albumId: Music.AlbumId,
  for child: Child,
) async throws -> Music.ResolvedAlbum? {
  do {
    return try await get(dependency: \.appleMusic).resolveAlbum(.init(
      storefront: child.appleMusicStorefront,
      albumId: albumId,
    ))
  } catch AppleMusicResolutionError.missingResource(type: "album", _) {
    return nil
  }
}

struct MusicAlbumCurationSource: Sendable {
  var album: Music.ResolvedAlbum
  var isUnavailableInStorefront: Bool
  var storedTrackGrants: [Music.ResolvedTrackGrant]?
}

struct MusicAlbumCuration: PairNestable, PairOutput {
  enum Scope: String, PairNestable {
    case none
    case selectedTracks
    case wholeAlbum
    case artist
  }

  struct Track: PairNestable {
    var id: Music.TrackId
    var title: String
    var artistName: String
    var artworkUrl: String?
    var durationInMillis: Int?
    var discNumber: Int?
    var trackNumber: Int?
    var contentRating: Music.ContentRating?
    var appleMusicUrl: String?
    var isSelected: Bool
  }

  var revision: Int64
  var id: Music.AlbumId
  var title: String
  var artistName: String
  var artworkUrl: String?
  var artwork: Music.Artwork?
  var releaseDate: String?
  var releaseType: String?
  var appleMusicUrl: String?
  var scope: Scope
  var selectedTrackCount: Int
  var catalogTrackCount: Int
  var canEdit: Bool
  var governingArtistId: Music.ArtistId?
  var governingArtistName: String?
  var isUnavailableInStorefront: Bool
  var tracks: [Track]
}

extension Music.CatalogPolicy.StoredPolicy {
  func albumCurationSource(
    _ albumId: Music.AlbumId,
    catalogAlbum: Music.ResolvedAlbum?,
  ) throws -> MusicAlbumCurationSource {
    if let catalogAlbum {
      return .init(album: catalogAlbum, isUnavailableInStorefront: false)
    }
    switch self.coverage.governingGrant(forAlbum: albumId) {
    case .artist(let grant)?:
      if let album = grant.resolution.albums.first(where: { $0.id == albumId }) {
        return .init(album: album, isUnavailableInStorefront: true)
      }
    case .album(let grant)?:
      return .init(album: grant.resolution, isUnavailableInStorefront: true)
    case .track?, nil:
      break
    }
    let grants = self.coverage.directTrackGrants(preferredAlbumId: albumId).map(\.resolution)
    guard let summary = grants.first?.preferredAlbum else {
      throw AppleMusicResolutionError.missingResource(type: "album", id: albumId.rawValue)
    }
    return .init(
      album: .init(summary, tracks: grants.map(\.track)),
      isUnavailableInStorefront: true,
      storedTrackGrants: grants,
    )
  }

  func planAlbumSelection(
    for source: MusicAlbumCurationSource,
    selectedTrackIds: [Music.TrackId],
  ) throws -> Music.CatalogPolicy.AlbumSelectionPlan {
    let plan = try self.coverage.planAlbumSelection(
      for: source.album,
      selectedTrackIds: selectedTrackIds,
    )
    guard let storedTrackGrants = source.storedTrackGrants else { return plan }
    switch plan {
    case .replaceWithAlbumGrant, .replaceWithTrackGrants:
      let selectedTrackIds = Set(selectedTrackIds)
      return .replaceWithTrackGrants(storedTrackGrants.filter {
        selectedTrackIds.contains($0.track.id)
      })
    case .removeDirectAuthorization, .coveredByArtist:
      return plan
    }
  }

  func albumCuration(
    _ source: MusicAlbumCurationSource,
    revision: Int64,
  ) -> MusicAlbumCuration {
    let album = source.album
    let scope: MusicAlbumCuration.Scope
    let selectedTrackIds: Set<Music.TrackId>
    let governingArtist: Music.CatalogPolicy.ArtistGrant?

    if case .artist(let artist)? = self.coverage.governingGrant(forAlbum: album.id) {
      scope = .artist
      selectedTrackIds = Set(album.tracks.map(\.id))
      governingArtist = artist
    } else if case .album? = self.coverage.governingGrant(forAlbum: album.id) {
      scope = .wholeAlbum
      selectedTrackIds = Set(album.tracks.map(\.id))
      governingArtist = nil
    } else {
      selectedTrackIds = Set(self.tracks(preferredAlbumId: album.id).map(\.appleMusicTrackId))
      scope = selectedTrackIds.isEmpty ? .none : .selectedTracks
      governingArtist = nil
    }

    return .init(
      revision: revision,
      id: album.id,
      title: album.title,
      artistName: album.artistName,
      artworkUrl: album.artworkUrl,
      artwork: album.artwork,
      releaseDate: album.releaseDate,
      releaseType: album.releaseType,
      appleMusicUrl: album.appleMusicUrl,
      scope: scope,
      selectedTrackCount: album.tracks.count { selectedTrackIds.contains($0.id) },
      catalogTrackCount: album.tracks.count,
      canEdit: scope != .artist,
      governingArtistId: governingArtist?.appleMusicArtistId,
      governingArtistName: governingArtist?.resolution.name,
      isUnavailableInStorefront: source.isUnavailableInStorefront,
      tracks: album.tracks.map {
        .init(
          id: $0.id,
          title: $0.title,
          artistName: $0.artistName,
          artworkUrl: $0.artworkUrl,
          durationInMillis: $0.durationInMillis,
          discNumber: $0.discNumber,
          trackNumber: $0.trackNumber,
          contentRating: $0.contentRating,
          appleMusicUrl: $0.appleMusicUrl,
          isSelected: selectedTrackIds.contains($0.id),
        )
      },
    )
  }
}
