import Foundation
import Tagged

struct ApprovedMusicLibrary: Codable, Equatable, Sendable {
  var albums: [ApprovedAlbum]
  var artists: [ApprovedArtist]

  init(
    albums: [ApprovedAlbum] = [],
    artists: [ApprovedArtist] = [],
  ) {
    self.albums = albums
    self.artists = artists
  }

  var isEmpty: Bool {
    self.albums.isEmpty && self.artists.isEmpty
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
    self.tracks = tracks
  }
}

struct ApprovedArtist: Codable, Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let name: String
  let catalogMetadata: ApprovedMusicCatalogMetadata?
  let releaseAlbumIds: [ApprovedAlbum.ID]?
  let topSongs: [ApprovedTrack]?

  init(
    id: ID,
    name: String,
    catalogMetadata: ApprovedMusicCatalogMetadata? = nil,
    releaseAlbumIds: [ApprovedAlbum.ID]? = nil,
    topSongs: [ApprovedTrack]? = nil,
  ) {
    self.id = id
    self.name = name
    self.catalogMetadata = catalogMetadata
    self.releaseAlbumIds = releaseAlbumIds
    self.topSongs = topSongs
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
  let albumTitle: String?
  let artworkURL: URL?
  let durationInMillis: Int?

  init(
    id: ID,
    title: String,
    artistName: String,
    albumTitle: String? = nil,
    artworkURL: URL? = nil,
    durationInMillis: Int? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.albumTitle = albumTitle
    self.artworkURL = artworkURL
    self.durationInMillis = durationInMillis
  }
}
