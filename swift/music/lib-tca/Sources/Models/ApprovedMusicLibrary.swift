import Foundation
import Tagged

struct ApprovedMusicLibrary: Equatable, Sendable {
  var albums: [ApprovedAlbum]

  init(albums: [ApprovedAlbum] = []) {
    self.albums = albums
  }

  var isEmpty: Bool {
    self.albums.isEmpty
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
  let tracks: [ApprovedTrack]

  init(
    id: ID,
    title: String,
    artistName: String,
    artworkURL: URL? = nil,
    showsArtwork: Bool = true,
    tracks: [ApprovedTrack] = [],
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL
    self.showsArtwork = showsArtwork
    self.tracks = tracks
  }
}

struct ApprovedTrack: Equatable, Identifiable, Sendable {
  typealias ID = Tagged<Self, String>

  let id: ID
  let title: String
  let artistName: String
  let artworkURL: URL?

  init(
    id: ID,
    title: String,
    artistName: String,
    artworkURL: URL? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL
  }
}
