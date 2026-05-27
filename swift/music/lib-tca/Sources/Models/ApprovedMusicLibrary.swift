import Foundation
import Tagged

struct ApprovedMusicLibrary: Equatable, Sendable {
  var albums: [ApprovedAlbum]
  var artists: [ApprovedArtist]
  var tracks: [ApprovedTrack]

  init(
    albums: [ApprovedAlbum] = [],
    artists: [ApprovedArtist] = [],
    tracks: [ApprovedTrack] = [],
  ) {
    self.albums = albums
    self.artists = artists
    self.tracks = tracks
  }

  var isEmpty: Bool {
    self.albums.isEmpty && self.artists.isEmpty && self.tracks.isEmpty
  }

  static let empty = Self()
}

struct ApprovedAlbum: Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let title: String
  let artistName: String
  let artworkURL: URL?
  let showsArtwork: Bool
  let trackIDs: [ApprovedTrack.ID]

  init(
    id: ID,
    title: String,
    artistName: String,
    artworkURL: URL? = nil,
    showsArtwork: Bool = true,
    trackIDs: [ApprovedTrack.ID],
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL
    self.showsArtwork = showsArtwork
    self.trackIDs = trackIDs
  }
}

struct ApprovedArtist: Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let name: String
  let artworkURL: URL?
  let showsArtwork: Bool
  let isRootAllowed: Bool
  let albumIDs: [ApprovedAlbum.ID]
  let trackIDs: [ApprovedTrack.ID]

  init(
    id: ID,
    name: String,
    artworkURL: URL? = nil,
    showsArtwork: Bool = true,
    isRootAllowed: Bool,
    albumIDs: [ApprovedAlbum.ID],
    trackIDs: [ApprovedTrack.ID],
  ) {
    self.id = id
    self.name = name
    self.artworkURL = artworkURL
    self.showsArtwork = showsArtwork
    self.isRootAllowed = isRootAllowed
    self.albumIDs = albumIDs
    self.trackIDs = trackIDs
  }
}

struct ApprovedTrack: Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let title: String
  let artistName: String
  let albumTitle: String?
  let albumID: ApprovedAlbum.ID?
  let artistIDs: [ApprovedArtist.ID]
  let artworkURL: URL?
  let showsArtwork: Bool

  init(
    id: ID,
    title: String,
    artistName: String,
    albumTitle: String? = nil,
    albumID: ApprovedAlbum.ID? = nil,
    artistIDs: [ApprovedArtist.ID],
    artworkURL: URL? = nil,
    showsArtwork: Bool = true,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.albumTitle = albumTitle
    self.albumID = albumID
    self.artistIDs = artistIDs
    self.artworkURL = artworkURL
    self.showsArtwork = showsArtwork
  }
}
