import ComposableArchitecture

@Reducer
enum LibraryPath {
  case album(AlbumDetailFeature)
  case artist(ArtistDetailFeature)
  case playlist(PlaylistDetailFeature)
}

extension LibraryPath.State: Equatable {}
extension LibraryPath.Action: Equatable {}

extension StackState<LibraryPath.State> {
  mutating func reconcile(with library: ApprovedMusicLibrary) {
    for id in Array(self.ids) {
      switch self[id: id] {
      case .album(var detail):
        guard let album = library.album(id: detail.album.id) else {
          self.pop(from: id)
          return
        }
        detail.album = album
        self[id: id] = .album(detail)

      case .artist(let detail):
        guard library.artist(id: detail.artistID) != nil else {
          self.pop(from: id)
          return
        }

      case .playlist(var detail):
        guard let playlist = library.playlist(id: detail.playlist.id) else {
          self.pop(from: id)
          return
        }
        detail.playlist = playlist
        self[id: id] = .playlist(detail)

      case nil:
        break
      }
    }
  }
}

@Reducer
struct ArtistDetailFeature {
  @ObservableState
  struct State: Equatable {
    let artistID: ApprovedArtist.ID
  }

  enum Action: Equatable {
    case addToPlaylistTapped
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
