import LibViews

extension AlbumData {
  init(album: ApprovedAlbum) {
    self.init(
      id: album.id.rawValue,
      title: album.title,
      artist: album.artistName,
      artworkUrl: album.artworkURL,
    )
  }
}

extension TrackData {
  init(track: ApprovedTrack) {
    self.init(
      id: track.id.rawValue,
      title: track.title,
      artist: track.artistName,
      artworkUrl: track.artworkURL,
    )
  }
}
