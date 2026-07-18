import Foundation
import Tagged

struct PlaybackItem: Codable, Equatable, Identifiable, Sendable {
  let id: ApprovedTrack.ID
  let title: String
  let artistName: String
  let artworkURL: URL?
  let albumID: ApprovedAlbum.ID?
  let albumTitle: String?
  let duration: TimeInterval?

  init(
    id: ApprovedTrack.ID,
    title: String,
    artistName: String,
    artworkURL: URL?,
    albumID: ApprovedAlbum.ID? = nil,
    albumTitle: String? = nil,
    duration: TimeInterval? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL?.normalizedArtworkURL
    self.albumID = albumID
    self.albumTitle = albumTitle
    self.duration = duration
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
      albumID: albumID ?? track.albumID,
      albumTitle: track.albumTitle,
      duration: track.durationInMillis.map { TimeInterval($0) / 1000 },
    )
  }

  func withAlbumID(_ albumID: ApprovedAlbum.ID?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: self.artworkURL,
      albumID: albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
    )
  }
}

private extension URL {
  var normalizedArtworkURL: URL {
    guard self.scheme?.lowercased() == "musickit",
          let fallbackValue = URLComponents(
            url: self,
            resolvingAgainstBaseURL: false,
          )?.queryItems?.first(where: { $0.name == "fat" })?.value,
          let fallbackURL = URL(string: fallbackValue),
          ["http", "https"].contains(fallbackURL.scheme?.lowercased()) else { return self }
    return fallbackURL
  }
}

struct PlaybackQueueEntry: Equatable, Identifiable, Sendable {
  let id: String
  let item: PlaybackItem
}

enum PlaybackQueueInsertionPosition: Equatable, Sendable {
  case next
  case tail
}

struct PlaybackSnapshot: Equatable, Sendable {
  let entries: [PlaybackQueueEntry]
  let currentEntryID: String?
  let playStatus: PlaybackFeature.PlayStatus
  let progress: PlaybackProgress

  static let empty = Self(
    entries: [],
    currentEntryID: nil,
    playStatus: .paused,
    progress: .zero,
  )
}
