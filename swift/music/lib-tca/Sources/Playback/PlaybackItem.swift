import Foundation
import Tagged

struct PlaylistPlaybackSource: Codable, Equatable, Sendable {
  let playlistID: UUID
  let entryID: UUID
}

struct PlaybackItem: Codable, Equatable, Identifiable, Sendable {
  let id: ApprovedTrack.ID
  let title: String
  let artistName: String
  let artworkURL: URL?
  let albumID: ApprovedAlbum.ID?
  let albumTitle: String?
  let duration: TimeInterval?
  let playlistSource: PlaylistPlaybackSource?

  init(
    id: ApprovedTrack.ID,
    title: String,
    artistName: String,
    artworkURL: URL?,
    albumID: ApprovedAlbum.ID? = nil,
    albumTitle: String? = nil,
    duration: TimeInterval? = nil,
    playlistSource: PlaylistPlaybackSource? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL?.normalizedArtworkURL
    self.albumID = albumID
    self.albumTitle = albumTitle
    self.duration = duration
    self.playlistSource = playlistSource
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
      playlistSource: self.playlistSource,
    )
  }

  func withPlaylistSource(_ playlistSource: PlaylistPlaybackSource?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: self.artworkURL,
      albumID: self.albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
      playlistSource: playlistSource,
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

enum PlaybackSourceHintMatcher {
  struct Occurrence: Equatable, Sendable {
    var item: PlaybackItem
    var retainedEntryID: PlaybackQueueEntry.ID?

    init(item: PlaybackItem, retainedEntryID: PlaybackQueueEntry.ID? = nil) {
      self.item = item
      self.retainedEntryID = retainedEntryID
    }
  }

  static func match(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
    existing: [PlaybackQueueEntry.ID: PlaylistPlaybackSource] = [:],
  ) -> [PlaybackQueueEntry.ID: PlaylistPlaybackSource] {
    let currentEntryIDs = Set(entries.map(\.id))
    var matched = existing.filter { currentEntryIDs.contains($0.key) }
    let entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

    for occurrence in plan {
      guard let retainedEntryID = occurrence.retainedEntryID,
            let entry = entriesByID[retainedEntryID],
            entry.item.id == occurrence.item.id else { continue }
      matched[retainedEntryID] = occurrence.item.playlistSource
    }

    for (occurrence, entry) in zip(plan, entries) {
      guard occurrence.item.id == entry.item.id else { break }
      matched[entry.id] = occurrence.item.playlistSource
    }

    return matched
  }
}
