import Foundation

struct LibraryCollectionIdentity: Codable, Equatable, Hashable, Sendable {
  enum Kind: String, Codable, Sendable {
    case album
    case artist
    case playlist
  }

  let kind: Kind
  let id: String

  static func album(_ id: ApprovedAlbum.ID) -> Self {
    Self(kind: .album, id: id.rawValue)
  }

  static func artist(_ id: ApprovedArtist.ID) -> Self {
    Self(kind: .artist, id: id.rawValue)
  }

  static func playlist(_ id: MusicPlaylist.ID) -> Self {
    Self(kind: .playlist, id: id.rawValue.uuidString)
  }
}

struct LibraryCollectionRecency: Codable, Equatable, Sendable {
  struct Record: Codable, Equatable, Sendable {
    var lastPlayedAt: Date
    var observedAddedAt: Date
  }

  var records: [LibraryCollectionIdentity: Record] = [:]

  mutating func recordPlay(
    of identity: LibraryCollectionIdentity,
    observedAddedAt: Date,
    at date: Date,
  ) {
    self.records[identity] = Record(
      lastPlayedAt: date,
      observedAddedAt: observedAddedAt,
    )
  }

  func lastPlayedAt(
    for identity: LibraryCollectionIdentity,
    observedAddedAt: Date,
  ) -> Date? {
    guard let record = self.records[identity],
          record.observedAddedAt == observedAddedAt else { return nil }
    return record.lastPlayedAt
  }
}
