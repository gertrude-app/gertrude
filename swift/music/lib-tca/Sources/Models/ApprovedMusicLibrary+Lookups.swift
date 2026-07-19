import Foundation

extension ApprovedMusicLibrary {
  func album(id: ApprovedAlbum.ID) -> ApprovedAlbum? {
    self.albums.first { $0.id == id }
  }

  func artist(id: ApprovedArtist.ID) -> ApprovedArtist? {
    self.artists.first { $0.id == id }
  }

  func playlist(id: MusicPlaylist.ID) -> MusicPlaylist? {
    self.playlists.first { $0.id == id }
  }

  func observedAddedAt(for identity: LibraryCollectionIdentity) -> Date? {
    switch identity.kind {
    case .album:
      self.albums.first(where: { $0.id.rawValue == identity.id })?.addedAt
    case .artist:
      self.artists.first(where: { $0.id.rawValue == identity.id })?.addedAt
    case .playlist:
      self.playlists.first(where: {
        $0.id.rawValue.uuidString == identity.id
      })?.createdAt
    }
  }

  func album(matching item: PlaybackItem) -> ApprovedAlbum? {
    if let albumID = item.albumID, let album = self.album(id: albumID) {
      return album
    }
    guard let albumTitle = item.albumTitle else { return nil }
    return self.albums
      .filter { album in
        album.title.localizedCaseInsensitiveCompare(albumTitle) == .orderedSame
          && (album.artistName.localizedCaseInsensitiveContains(item.artistName)
            || item.artistName.localizedCaseInsensitiveContains(album.artistName))
      }
      .sorted { lhs, rhs in
        let lhsContainsTrack = lhs.tracks.contains(where: { $0.id == item.id })
        let rhsContainsTrack = rhs.tracks.contains(where: { $0.id == item.id })
        if lhsContainsTrack != rhsContainsTrack {
          return lhsContainsTrack
        }
        return lhs.id.rawValue < rhs.id.rawValue
      }
      .first
  }
}
