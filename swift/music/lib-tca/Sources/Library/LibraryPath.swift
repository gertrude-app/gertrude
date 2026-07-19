import ComposableArchitecture

@Reducer
enum LibraryPath {
  case album(AlbumDetailFeature)
  case artist(ArtistDetailFeature)
  case playlist(PlaylistDetailFeature)
}

extension LibraryPath.State: Equatable {}
extension LibraryPath.Action: Equatable {}

@Reducer
struct ArtistDetailFeature {
  @ObservableState
  struct State: Equatable {
    let artistID: ApprovedArtist.ID
  }

  enum Action: Equatable {
    case addToQueueTapped
    case playButtonTapped
    case playNextTapped
    case releaseAddToPlaylistTapped(ApprovedAlbum.ID)
    case releaseAddToQueueTapped(ApprovedAlbum.ID)
    case releasePlayNextTapped(ApprovedAlbum.ID)
    case releaseTapped(ApprovedAlbum.ID)
    case topSongAddToPlaylistTapped(ApprovedTrack.ID)
    case topSongAddToQueueTapped(ApprovedTrack.ID)
    case topSongPlayNextTapped(ApprovedTrack.ID)
    case topSongTapped(ApprovedTrack.ID)
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
