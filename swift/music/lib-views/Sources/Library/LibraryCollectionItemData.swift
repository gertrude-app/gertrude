import Foundation

public enum LibraryFilter: String, CaseIterable, Equatable, Hashable, Sendable {
  case playlists
  case artists
  case albums

  public var title: String {
    switch self {
    case .playlists:
      "Playlists"
    case .artists:
      "Artists"
    case .albums:
      "Albums"
    }
  }
}

public enum LibraryCollectionItemData: Equatable, Identifiable, Sendable {
  case album(AlbumData)
  case artist(ArtistData)
  case playlist(PlaylistData)

  public var id: String {
    switch self {
    case .album(let album):
      "album-\(album.id)"
    case .artist(let artist):
      "artist-\(artist.id)"
    case .playlist(let playlist):
      "playlist-\(playlist.id)"
    }
  }

  func isIncluded(in filter: LibraryFilter?) -> Bool {
    guard let filter else { return true }
    return switch (filter, self) {
    case (.albums, .album), (.artists, .artist), (.playlists, .playlist):
      true
    default:
      false
    }
  }
}
