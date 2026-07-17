extension ApprovedMusicLibrary {
  func album(id: ApprovedAlbum.ID) -> ApprovedAlbum? {
    self.albums.first { $0.id == id }
  }

  func artist(id: ApprovedArtist.ID) -> ApprovedArtist? {
    self.artists.first { $0.id == id }
  }

  func album(matching item: PlaybackItem) -> ApprovedAlbum? {
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
