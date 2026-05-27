import Foundation
import Tagged

struct PlaybackItem: Equatable, Identifiable, Sendable {
  let id: ApprovedTrack.ID
  let title: String
  let artistName: String
  let artworkURL: URL?
  let allowsArtwork: Bool

  init(
    id: ApprovedTrack.ID,
    title: String,
    artistName: String,
    artworkURL: URL?,
    allowsArtwork: Bool,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL
    self.allowsArtwork = allowsArtwork
  }

  init(
    track: ApprovedTrack,
    artworkURL: URL?,
    allowsArtwork: Bool,
  ) {
    self.init(
      id: track.id,
      title: track.title,
      artistName: track.artistName,
      artworkURL: artworkURL,
      allowsArtwork: allowsArtwork,
    )
  }
}
