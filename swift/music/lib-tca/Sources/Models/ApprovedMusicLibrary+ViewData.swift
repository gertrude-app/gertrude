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

extension ArtistData {
  init(artist: ApprovedArtist) {
    self.init(
      id: artist.id.rawValue,
      name: artist.name,
      artworkUrl: artist.artworkURL,
      showsArtwork: artist.showsArtwork,
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
      showsArtwork: track.showsArtwork,
    )
  }
}
