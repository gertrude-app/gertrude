import Foundation
import Tagged

struct PlaylistPlaybackSource: Codable, Equatable, Sendable {
  let playlistID: UUID
  let entryID: UUID
}

struct PlaybackContext: Codable, Equatable, Sendable {
  let identity: LibraryCollectionIdentity
  let title: String
}

enum PlaybackQueueRole: String, Codable, Equatable, Sendable {
  case context
  case queued
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
  let queueRole: PlaybackQueueRole?

  init(
    id: ApprovedTrack.ID,
    title: String,
    artistName: String,
    artworkURL: URL?,
    albumID: ApprovedAlbum.ID? = nil,
    albumTitle: String? = nil,
    duration: TimeInterval? = nil,
    playlistSource: PlaylistPlaybackSource? = nil,
    queueRole: PlaybackQueueRole? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL?.normalizedArtworkURL
    self.albumID = albumID
    self.albumTitle = albumTitle
    self.duration = duration
    self.playlistSource = playlistSource
    self.queueRole = queueRole
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
      queueRole: self.queueRole,
    )
  }

  func withArtworkURL(_ artworkURL: URL?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: artworkURL,
      albumID: self.albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
      playlistSource: self.playlistSource,
      queueRole: self.queueRole,
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
      queueRole: self.queueRole,
    )
  }

  func withQueueRole(_ queueRole: PlaybackQueueRole?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: self.artworkURL,
      albumID: self.albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
      playlistSource: self.playlistSource,
      queueRole: queueRole,
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
  let viewID: String

  init(
    id: String,
    item: PlaybackItem,
    viewID: String? = nil,
  ) {
    self.id = id
    self.item = item
    self.viewID = viewID ?? id
  }

  var role: PlaybackQueueRole {
    self.item.queueRole ?? .queued
  }
}

enum PlaybackQueueInsertionPosition: Equatable, Sendable {
  case next
  case tail
}

enum PlaybackQueueInsertionTarget: Equatable, Sendable {
  case before(PlaybackQueueEntry)
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

  func hasSameSession(as other: Self) -> Bool {
    self.entries == other.entries
      && self.currentEntryID == other.currentEntryID
      && self.playStatus == other.playStatus
  }
}

enum PlaybackMetadataHintMatcher {
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
    self.match(
      plan: plan,
      entries: entries,
      existing: existing,
      value: { $0.playlistSource },
    )
  }

  static func match<Value>(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
    existing: [PlaybackQueueEntry.ID: Value] = [:],
    value: (PlaybackItem) -> Value?,
  ) -> [PlaybackQueueEntry.ID: Value] {
    let currentEntryIDs = Set(entries.map(\.id))
    var matched = existing.filter { currentEntryIDs.contains($0.key) }
    let entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

    for occurrence in plan {
      guard let retainedEntryID = occurrence.retainedEntryID,
            let entry = entriesByID[retainedEntryID],
            entry.item.id == occurrence.item.id else { continue }
      matched[retainedEntryID] = value(occurrence.item)
    }

    for (occurrence, entry) in zip(plan, entries) {
      guard occurrence.item.id == entry.item.id else { break }
      matched[entry.id] = value(occurrence.item)
    }

    return matched
  }
}
