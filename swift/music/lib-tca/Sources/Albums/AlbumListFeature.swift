import ComposableArchitecture

@Reducer
struct AlbumListFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    let albums: [ApprovedAlbum]
    let tracks: [ApprovedTrack]
    @Presents var destination: Destination.State?

    init(
      albums: [ApprovedAlbum],
      tracks: [ApprovedTrack],
      destination: Destination.State? = nil,
    ) {
      self.albums = albums
      self.tracks = tracks
      self.destination = destination
    }
  }

  @Reducer
  enum Destination {
    case album(AlbumDetailFeature)
  }

  enum Action: Equatable {
    case albumTapped(ApprovedAlbum.ID)
    case albumDetailDismissed(String)
    case delegate(AlbumDetailFeature.Action.DelegateAction)
    case destination(PresentationAction<Destination.Action>)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .albumTapped(let albumID):
        guard let albumDetail = self.albumDetail(albumID, in: state) else { return .none }
        state.destination = .album(albumDetail)
        return .none

      case .albumDetailDismissed(let pushID):
        guard case .some(.album(let albumDetail)) = state.destination,
              albumDetail.pushID == pushID
        else { return .none }
        state.destination = nil
        return .none

      case .destination(.presented(.album(.delegate(let delegateAction)))):
        return .send(.delegate(delegateAction))

      case .delegate, .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }

  private func albumDetail(_ albumID: ApprovedAlbum.ID, in state: State) -> AlbumDetailFeature.State? {
    let library = ApprovedMusicLibrary(albums: state.albums, tracks: state.tracks)
    guard let album = library.album(id: albumID) else { return nil }
    return .init(
      album: album,
      tracks: library.tracks(for: album),
      transitionSourceID: albumID.rawValue,
    )
  }
}

extension AlbumListFeature.State {
  mutating func setAlbumDetailPlaybackStatus(_ status: PlaybackFeature.Status) {
    guard case .some(.album(var albumDetail)) = self.destination else { return }
    albumDetail.setPlaybackStatus(status)
    self.destination = .album(albumDetail)
  }
}

extension AlbumListFeature.Destination.State: Equatable {}
extension AlbumListFeature.Destination.Action: Equatable {}
