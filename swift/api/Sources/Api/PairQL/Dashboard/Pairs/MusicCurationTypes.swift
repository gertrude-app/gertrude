import Foundation
import PairQL

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

struct MusicAlbumCurationMutationOutput: PairOutput {
  enum Status: String, PairNestable {
    case updated
    case conflict
    case coveredByArtist
  }

  var status: Status
  var curation: MusicCurationOutput
  var album: MusicAlbumCuration
}

struct MusicArtistApprovalOutput: PairOutput {
  enum Status: String, PairNestable {
    case updated
    case confirmationRequired
  }

  struct Confirmation: PairNestable {
    var revision: Int64
    var token: String
    var albumCount: Int
    var trackCount: Int
  }

  var status: Status
  var curation: MusicCurationOutput
  var confirmation: Confirmation?
}

extension Music.CatalogPolicy.StoredPolicy {
  func curation(revision: Int64) -> MusicCurationOutput {
    var albumsById: [Music.AlbumId: MusicCurationOutput.Album] = [:]

    for album in self.albums {
      guard case .album? = self.coverage.governingGrant(forAlbum: album.appleMusicAlbumId),
            let resolution = album.resolution else { continue }
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
      governingArtistName: governingArtist?.resolution?.name,
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

  private static func trackMetadataOrder(
    _ lhs: Music.ApprovedTrack,
    _ rhs: Music.ApprovedTrack,
  ) -> Bool {
    if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
    return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
  }
}
