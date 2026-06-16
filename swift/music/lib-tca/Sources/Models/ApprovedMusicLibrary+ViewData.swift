import LibViews

extension AlbumData {
  init(album: ApprovedAlbum) {
    self.init(
      id: album.id.rawValue,
      title: album.title,
      artist: album.artistName,
      artworkUrl: album.artworkURL,
      showsArtwork: album.showsArtwork,
    )
  }
}

extension TrackData {
  init(track: ApprovedTrack, showsArtwork: Bool) {
    self.init(
      id: track.id.rawValue,
      title: track.title,
      artist: track.artistName,
      artworkUrl: track.artworkURL,
      showsArtwork: showsArtwork,
    )
  }
}
