import Foundation
import Tagged

struct ApprovedMusicLibrary: Codable, Equatable, Sendable {
  var schemaVersion: Int
  var revision: Int64
  var generatedAt: Date
  var albums: [ApprovedAlbum]
  var artists: [ApprovedArtist]

  init(
    schemaVersion: Int = 3,
    revision: Int64 = 0,
    generatedAt: Date = .init(timeIntervalSince1970: 0),
    albums: [ApprovedAlbum] = [],
    artists: [ApprovedArtist] = [],
  ) {
    self.schemaVersion = schemaVersion
    self.revision = revision
    self.generatedAt = generatedAt
    self.albums = albums
    self.artists = artists
  }

  var isEmpty: Bool {
    self.albums.isEmpty && self.artists.isEmpty
  }

  var hasCompleteSnapshot: Bool {
    guard self.schemaVersion == 3, self.revision >= 0 else { return false }
    var albumsById: [ApprovedAlbum.ID: ApprovedAlbum] = [:]
    for album in self.albums {
      guard !album.id.rawValue.isEmpty, albumsById[album.id] == nil else { return false }
      guard Set(album.tracks.map(\.id)).count == album.tracks.count else { return false }
      guard album.tracks.allSatisfy({
        !$0.id.rawValue.isEmpty && $0.albumID == album.id
      }) else { return false }
      albumsById[album.id] = album
    }

    var artistIds = Set<ApprovedArtist.ID>()
    for artist in self.artists {
      guard !artist.id.rawValue.isEmpty, artistIds.insert(artist.id).inserted else {
        return false
      }
      guard let releaseAlbumIds = artist.releaseAlbumIds,
            let topSongs = artist.topSongs else { return false }
      guard Set(releaseAlbumIds).count == releaseAlbumIds.count else { return false }
      guard releaseAlbumIds.allSatisfy({ albumsById[$0] != nil }) else { return false }
      var topSongIds = Set<ApprovedTrack.ID>()
      for song in topSongs {
        guard topSongIds.insert(song.id).inserted,
              let albumId = song.albumID,
              let album = albumsById[albumId],
              album.tracks.contains(where: { $0.id == song.id }) else { return false }
      }
    }
    return true
  }

  static let empty = Self()
}

struct ApprovedAlbum: Codable, Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let title: String
  let artistName: String
  let artworkURL: URL?
  let artwork: ApprovedMusicArtwork?
  let trackCount: Int?
  let releaseDate: String?
  let releaseType: String?
  let addedAt: Date
  var tracks: [ApprovedTrack]

  init(
    id: ID,
    title: String,
    artistName: String,
    artworkURL: URL? = nil,
    artwork: ApprovedMusicArtwork? = nil,
    trackCount: Int? = nil,
    releaseDate: String? = nil,
    releaseType: String? = nil,
    addedAt: Date = .init(timeIntervalSince1970: 0),
    tracks: [ApprovedTrack] = [],
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL
    self.artwork = artwork
    self.trackCount = trackCount
    self.releaseDate = releaseDate
    self.releaseType = releaseType
    self.addedAt = addedAt
    self.tracks = tracks.map { $0.withAlbumID($0.albumID ?? id) }
  }
}

struct ApprovedArtist: Codable, Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let name: String
  let catalogMetadata: ApprovedMusicCatalogMetadata?
  let releaseAlbumIds: [ApprovedAlbum.ID]?
  let topSongs: [ApprovedTrack]?
  let addedAt: Date

  init(
    id: ID,
    name: String,
    catalogMetadata: ApprovedMusicCatalogMetadata? = nil,
    releaseAlbumIds: [ApprovedAlbum.ID]? = nil,
    topSongs: [ApprovedTrack]? = nil,
    addedAt: Date = .init(timeIntervalSince1970: 0),
  ) {
    self.id = id
    self.name = name
    self.catalogMetadata = catalogMetadata
    self.releaseAlbumIds = releaseAlbumIds
    self.topSongs = topSongs
    self.addedAt = addedAt
  }
}

struct ApprovedMusicCatalogMetadata: Codable, Equatable, Sendable {
  let artwork: ApprovedMusicArtwork?
  let editorialNotes: ApprovedMusicEditorialNotes?
  let appleMusicUrl: String?
  let genreNames: [String]

  init(
    artwork: ApprovedMusicArtwork? = nil,
    editorialNotes: ApprovedMusicEditorialNotes? = nil,
    appleMusicUrl: String? = nil,
    genreNames: [String] = [],
  ) {
    self.artwork = artwork
    self.editorialNotes = editorialNotes
    self.appleMusicUrl = appleMusicUrl
    self.genreNames = genreNames
  }
}

struct ApprovedMusicArtwork: Codable, Equatable, Sendable {
  let url: String?
  let width: Int?
  let height: Int?
  let bgColor: String?
  let textColor1: String?
  let textColor2: String?
  let textColor3: String?
  let textColor4: String?

  init(
    url: String? = nil,
    width: Int? = nil,
    height: Int? = nil,
    bgColor: String? = nil,
    textColor1: String? = nil,
    textColor2: String? = nil,
    textColor3: String? = nil,
    textColor4: String? = nil,
  ) {
    self.url = url
    self.width = width
    self.height = height
    self.bgColor = bgColor
    self.textColor1 = textColor1
    self.textColor2 = textColor2
    self.textColor3 = textColor3
    self.textColor4 = textColor4
  }
}

struct ApprovedMusicEditorialNotes: Codable, Equatable, Sendable {
  let tagline: String?
  let short: String?
  let standard: String?
  let name: String?

  init(
    tagline: String? = nil,
    short: String? = nil,
    standard: String? = nil,
    name: String? = nil,
  ) {
    self.tagline = tagline
    self.short = short
    self.standard = standard
    self.name = name
  }
}

struct ApprovedTrack: Codable, Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let title: String
  let artistName: String
  let albumID: ApprovedAlbum.ID?
  let albumTitle: String?
  let artworkURL: URL?
  let durationInMillis: Int?

  init(
    id: ID,
    title: String,
    artistName: String,
    albumID: ApprovedAlbum.ID? = nil,
    albumTitle: String? = nil,
    artworkURL: URL? = nil,
    durationInMillis: Int? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.albumID = albumID
    self.albumTitle = albumTitle
    self.artworkURL = artworkURL
    self.durationInMillis = durationInMillis
  }

  func withAlbumID(_ albumID: ApprovedAlbum.ID?) -> Self {
    .init(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      albumID: albumID,
      albumTitle: self.albumTitle,
      artworkURL: self.artworkURL,
      durationInMillis: self.durationInMillis,
    )
  }
}
