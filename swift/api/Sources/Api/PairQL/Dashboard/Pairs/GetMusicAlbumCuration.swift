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
    let album = try await get(dependency: \.appleMusic).resolveAlbum(.init(
      storefront: child.appleMusicStorefront,
      albumId: input.appleMusicAlbumId,
    ))
    let policy = try await Music.CatalogPolicy.load(childId: child.id, in: context.db)
    let revision = try await musicCurationRevision(
      childId: child.id,
      policy: policy,
      in: context.db,
      context: context,
    )
    return policy.albumCuration(album: album, revision: revision)
  }
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
  var tracks: [Track]
}

extension Music.CatalogPolicy.StoredPolicy {
  func albumCuration(
    album: Music.ResolvedAlbum,
    revision: Int64,
  ) -> MusicAlbumCuration {
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
