import Foundation
import Tagged

struct PlaybackItem: Equatable, Identifiable, Sendable {
  let id: ApprovedTrack.ID
  let title: String
  let artistName: String
  let artworkURL: URL?
  let albumID: ApprovedAlbum.ID?

  init(
    id: ApprovedTrack.ID,
    title: String,
    artistName: String,
    artworkURL: URL?,
    albumID: ApprovedAlbum.ID? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL
    self.albumID = albumID
  }

  init(
    track: ApprovedTrack,
    artworkURL: URL?,
    albumID: ApprovedAlbum.ID? = nil,
  ) {
    self.init(
      id: track.id,
      title: track.title,
      artistName: track.artistName,
      artworkURL: artworkURL,
      albumID: albumID,
    )
  }
}
