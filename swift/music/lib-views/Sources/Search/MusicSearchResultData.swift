import Foundation

public enum MusicSearchResultKind: Equatable, Sendable {
  case album
  case artist
  case playlist
  case song

  var title: String {
    switch self {
    case .album:
      "Album"
    case .artist:
      "Artist"
    case .playlist:
      "Playlist"
    case .song:
      "Song"
    }
  }
}

public struct MusicSearchResultData: Equatable, Identifiable, Sendable {
  public let id: String
  public let kind: MusicSearchResultKind
  public let collectionID: String
  public let title: String
  public let detail: String?
  public let artworkURL: URL?
  public let playlistArtworkURLs: [URL]

  public init(
    id: String,
    kind: MusicSearchResultKind,
    collectionID: String,
    title: String,
    detail: String? = nil,
    artworkURL: URL? = nil,
    playlistArtworkURLs: [URL] = [],
  ) {
    self.id = id
    self.kind = kind
    self.collectionID = collectionID
    self.title = title
    self.detail = detail
    self.artworkURL = artworkURL
    self.playlistArtworkURLs = playlistArtworkURLs
  }

  var subtitle: String {
    [self.kind.title, self.detail]
      .compactMap { value in
        guard let value, !value.isEmpty else { return nil }
        return value
      }
      .joined(separator: " · ")
  }
}
