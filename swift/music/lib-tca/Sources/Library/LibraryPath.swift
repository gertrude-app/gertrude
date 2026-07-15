import ComposableArchitecture

@Reducer
enum LibraryPath {
  case album(AlbumDetailFeature)
  case artist(ArtistDetailFeature)
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
    case playButtonTapped
    case releaseTapped(ApprovedAlbum.ID)
    case topSongTapped(ApprovedTrack.ID)
  }

  var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
