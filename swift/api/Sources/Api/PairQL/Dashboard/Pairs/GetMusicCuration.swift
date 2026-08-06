import DuetSQL
import Foundation
import PairQL

struct GetMusicCuration: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
  }

  typealias Output = MusicCurationOutput
}

extension GetMusicCuration: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    return try await currentMusicCuration(
      childId: child.id,
      in: context.db,
      context: context,
    )
  }
}

func currentMusicCuration(
  childId: Child.Id,
  in db: any DuetSQL.Client,
  context: ParentContext,
) async throws -> MusicCurationOutput {
  let policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
  let revision = try await musicCurationRevision(
    childId: childId,
    policy: policy,
    in: db,
    context: context,
  )
  return policy.curation(revision: revision)
}

func musicCurationRevision(
  childId: Child.Id,
  policy: Music.CatalogPolicy.StoredPolicy,
  in db: any DuetSQL.Client,
  context: ParentContext,
) async throws -> Int64 {
  guard let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
    for: childId,
    in: db,
  ) else {
    guard policy.albums.isEmpty, policy.artists.isEmpty, policy.tracks.isEmpty else {
      throw context.error(
        "c56ee45b",
        .serverError,
        "Music grants exist without a published snapshot for child `\(childId)`",
      )
    }
    return 0
  }
  guard snapshot.revision == snapshot.payload.revision else {
    throw context.error(
      "31f9c801",
      .serverError,
      "Music snapshot revision mismatch for child `\(childId)`",
    )
  }
  return snapshot.revision
}

struct MusicCurationOutput: PairOutput {
  struct Album: PairNestable {
    enum Scope: String, PairNestable {
      case selectedTracks
      case wholeAlbum
    }

    var id: Music.AlbumId
    var title: String
    var artistName: String
    var artworkUrl: String?
    var artwork: Music.Artwork?
    var catalogTrackCount: Int
    var selectedTrackCount: Int
    var releaseDate: String?
    var releaseType: String?
    var appleMusicUrl: String?
    var scope: Scope
    var showsArtwork: Bool
    var createdAt: Date
  }

  struct Artist: PairNestable {
    var id: Music.ArtistId
    var name: String
    var catalogMetadata: Music.CatalogMetadata?
    var createdAt: Date
  }

  var revision: Int64
  var albums: [Album]
  var artists: [Artist]
}

extension Music.CatalogPolicy.StoredPolicy {
  func curation(revision: Int64) -> MusicCurationOutput {
    var albumsById: [Music.AlbumId: MusicCurationOutput.Album] = [:]

    for album in self.albums {
      guard case .album? = self.coverage.governingGrant(
        forAlbum: album.appleMusicAlbumId,
      ) else { continue }
      let resolution = album.resolution
      albumsById[album.appleMusicAlbumId] = .init(
        id: resolution.id,
        title: resolution.title,
        artistName: resolution.artistName,
        artworkUrl: resolution.artworkUrl,
        artwork: resolution.artwork,
        catalogTrackCount: resolution.tracks.count,
        selectedTrackCount: resolution.tracks.count,
        releaseDate: resolution.releaseDate,
        releaseType: resolution.releaseType,
        appleMusicUrl: resolution.appleMusicUrl,
        scope: .wholeAlbum,
        showsArtwork: album.showsArtwork,
        createdAt: album.createdAt,
      )
    }

    let directTracks = self.tracks.filter {
      if case .track? = self.coverage.governingGrant(
        forTrack: $0.appleMusicTrackId,
        preferredAlbumId: $0.preferredAlbumId,
      ) {
        return true
      }
      return false
    }
    for (albumId, tracks) in Dictionary(grouping: directTracks, by: \.preferredAlbumId) {
      guard albumsById[albumId] == nil,
            let metadata = tracks.min(by: Self.trackMetadataOrder) else { continue }
      let summary = metadata.resolution.preferredAlbum
      albumsById[albumId] = .init(
        id: summary.id,
        title: summary.title,
        artistName: summary.artistName,
        artworkUrl: summary.artworkUrl,
        artwork: summary.artwork,
        catalogTrackCount: summary.trackCount,
        selectedTrackCount: Set(tracks.map(\.appleMusicTrackId)).count,
        releaseDate: summary.releaseDate,
        releaseType: summary.releaseType,
        appleMusicUrl: summary.appleMusicUrl,
        scope: .selectedTracks,
        showsArtwork: metadata.showsArtwork,
        createdAt: tracks.map(\.createdAt).min()!,
      )
    }

    let albums = albumsById.values.sorted {
      if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
      return $0.id.rawValue < $1.id.rawValue
    }
    let artists = self.artists.sorted {
      if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
      return $0.appleMusicArtistId.rawValue < $1.appleMusicArtistId.rawValue
    }.map {
      MusicCurationOutput.Artist(
        id: $0.appleMusicArtistId,
        name: $0.name,
        catalogMetadata: $0.catalogMetadata,
        createdAt: $0.createdAt,
      )
    }
    return .init(revision: revision, albums: albums, artists: artists)
  }

  private static func trackMetadataOrder(
    _ lhs: Music.ApprovedTrack,
    _ rhs: Music.ApprovedTrack,
  ) -> Bool {
    if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
    return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
  }
}
