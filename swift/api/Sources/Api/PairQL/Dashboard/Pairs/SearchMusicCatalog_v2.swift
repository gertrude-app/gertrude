import Dependencies
import PairQL

struct SearchMusicCatalog_v2: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var query: String
    var limit: Int?
  }

  struct Output: PairOutput {
    struct Track: PairNestable {
      struct Status: PairNestable {
        enum Kind: String, PairNestable {
          case available
          case selected
          case allowedWithAlbum
          case allowedWithArtist
        }

        var kind: Kind
        var managementAlbumId: Music.AlbumId?
        var governingArtistId: Music.ArtistId?
        var governingArtistName: String?
      }

      var id: Music.TrackId
      var title: String
      var artistName: String
      var preferredAlbumId: Music.AlbumId
      var albumTitle: String
      var artworkUrl: String?
      var artwork: Music.Artwork?
      var durationInMillis: Int?
      var discNumber: Int?
      var trackNumber: Int?
      var contentRating: Music.ContentRating?
      var appleMusicUrl: String?
      var status: Status
    }

    struct Album: PairNestable {
      struct Status: PairNestable {
        enum Kind: String, PairNestable {
          case available
          case selectedTracks
          case wholeAlbum
          case allowedWithArtist
        }

        var kind: Kind
        var selectedTrackCount: Int
        var governingArtistId: Music.ArtistId?
        var governingArtistName: String?
      }

      var id: Music.AlbumId
      var title: String
      var artistName: String
      var artworkUrl: String?
      var artwork: Music.Artwork?
      var trackCount: Int?
      var releaseDate: String?
      var releaseType: String?
      var appleMusicUrl: String?
      var status: Status
    }

    struct Artist: PairNestable {
      enum Status: String, PairNestable {
        case available
        case allowed
      }

      var id: Music.ArtistId
      var name: String
      var catalogMetadata: Music.CatalogMetadata?
      var status: Status
    }

    struct Item: PairNestable {
      enum Kind: String, PairNestable {
        case track
        case album
        case artist
      }

      var kind: Kind
      var track: Track?
      var album: Album?
      var artist: Artist?
    }

    var revision: Int64
    var items: [Item]
  }
}

extension SearchMusicCatalog_v2: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let policy = try await Music.CatalogPolicy.load(childId: child.id, in: context.db)
    let revision = try await musicCurationRevision(
      childId: child.id,
      policy: policy,
      in: context.db,
      context: context,
    )
    let query = input.query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return .init(revision: revision, items: []) }
    let results = try await get(dependency: \.appleMusic).searchCatalog(.init(
      term: query,
      limit: min(max(input.limit ?? 10, 1), 25),
    ))
    return .init(
      revision: revision,
      items: results.items.map { item in
        switch item {
        case .track(let track):
          .init(
            kind: .track,
            track: outputTrack(track, policy: policy),
            album: nil,
            artist: nil,
          )
        case .album(let album):
          .init(
            kind: .album,
            track: nil,
            album: outputAlbum(album, policy: policy),
            artist: nil,
          )
        case .artist(let artist):
          .init(
            kind: .artist,
            track: nil,
            album: nil,
            artist: .init(
              id: artist.id,
              name: artist.name,
              catalogMetadata: artist.catalogMetadata,
              status: policy.artist(artist.id) == nil ? .available : .allowed,
            ),
          )
        }
      },
    )
  }
}

private func outputTrack(
  _ track: AppleMusicCatalogSearchTrack,
  policy: Music.CatalogPolicy.StoredPolicy,
) -> SearchMusicCatalog_v2.Output.Track {
  let governingGrant = policy.coverage.governingGrant(forAlbum: track.preferredAlbumId)
    ?? policy.coverage.governingGrant(
      forTrack: track.id,
      preferredAlbumId: track.preferredAlbumId,
    )
  let status: SearchMusicCatalog_v2.Output.Track.Status = switch governingGrant {
  case .artist(let artist)?:
    .init(
      kind: .allowedWithArtist,
      managementAlbumId: nil,
      governingArtistId: artist.appleMusicArtistId,
      governingArtistName: artist.resolution?.name,
    )
  case .album(let album)?:
    .init(
      kind: .allowedWithAlbum,
      managementAlbumId: album.appleMusicAlbumId,
      governingArtistId: nil,
      governingArtistName: nil,
    )
  case .track(let grant)?:
    .init(
      kind: .selected,
      managementAlbumId: grant.preferredAlbumId,
      governingArtistId: nil,
      governingArtistName: nil,
    )
  case nil:
    .init(
      kind: .available,
      managementAlbumId: track.preferredAlbumId,
      governingArtistId: nil,
      governingArtistName: nil,
    )
  }
  return .init(
    id: track.id,
    title: track.title,
    artistName: track.artistName,
    preferredAlbumId: track.preferredAlbumId,
    albumTitle: track.albumTitle,
    artworkUrl: track.artworkUrl,
    artwork: track.artwork,
    durationInMillis: track.durationInMillis,
    discNumber: track.discNumber,
    trackNumber: track.trackNumber,
    contentRating: track.contentRating,
    appleMusicUrl: track.appleMusicUrl,
    status: status,
  )
}

private func outputAlbum(
  _ album: AppleMusicCatalogAlbum,
  policy: Music.CatalogPolicy.StoredPolicy,
) -> SearchMusicCatalog_v2.Output.Album {
  let status: SearchMusicCatalog_v2.Output.Album.Status
  switch policy.coverage.governingGrant(forAlbum: album.id) {
  case .artist(let artist)?:
    status = .init(
      kind: .allowedWithArtist,
      selectedTrackCount: 0,
      governingArtistId: artist.appleMusicArtistId,
      governingArtistName: artist.resolution?.name,
    )
  case .album?:
    status = .init(
      kind: .wholeAlbum,
      selectedTrackCount: album.trackCount ?? 0,
      governingArtistId: nil,
      governingArtistName: nil,
    )
  case .track?, nil:
    let selectedCount = policy.coverage.directTrackGrants(preferredAlbumId: album.id)
      .count { grant in
        if case .track? = policy.coverage.governingGrant(
          forTrack: grant.appleMusicTrackId,
          preferredAlbumId: album.id,
        ) {
          return true
        }
        return false
      }
    status = .init(
      kind: selectedCount == 0 ? .available : .selectedTracks,
      selectedTrackCount: selectedCount,
      governingArtistId: nil,
      governingArtistName: nil,
    )
  }
  return .init(
    id: album.id,
    title: album.title,
    artistName: album.artistName,
    artworkUrl: album.artworkUrl,
    artwork: album.artwork,
    trackCount: album.trackCount,
    releaseDate: album.releaseDate,
    releaseType: album.releaseType,
    appleMusicUrl: album.appleMusicUrl,
    status: status,
  )
}
