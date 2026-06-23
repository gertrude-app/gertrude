import Foundation
import Tagged

struct PlaybackItem: Equatable, Identifiable, Sendable {
  let id: ApprovedTrack.ID
  let title: String
  let artistName: String
  let artworkURL: URL?

  init(
    id: ApprovedTrack.ID,
    title: String,
    artistName: String,
    artworkURL: URL?,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL
  }

  init(
    track: ApprovedTrack,
    artworkURL: URL?,
  ) {
    self.init(
      id: track.id,
      title: track.title,
      artistName: track.artistName,
      artworkURL: artworkURL,
    )
  }
}
