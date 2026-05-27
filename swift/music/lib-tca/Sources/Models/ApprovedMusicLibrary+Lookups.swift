extension ApprovedMusicLibrary {
  func album(id: ApprovedAlbum.ID) -> ApprovedAlbum? {
    self.albums.first { $0.id == id }
  }

  func artist(id: ApprovedArtist.ID) -> ApprovedArtist? {
    self.artists.first { $0.id == id }
  }

  func track(id: ApprovedTrack.ID) -> ApprovedTrack? {
    self.tracks.first { $0.id == id }
  }

  func tracks(for album: ApprovedAlbum) -> [ApprovedTrack] {
    album.trackIDs.compactMap(self.track(id:))
  }

  func tracks(for albumID: ApprovedAlbum.ID) -> [ApprovedTrack] {
    guard let album = self.album(id: albumID) else { return [] }
    return self.tracks(for: album)
  }
}
