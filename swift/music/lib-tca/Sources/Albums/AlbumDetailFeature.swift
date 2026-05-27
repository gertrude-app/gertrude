import ComposableArchitecture

@Reducer
struct AlbumDetailFeature {
  @ObservableState
  struct State: Equatable {
    let album: ApprovedAlbum
    let tracks: [ApprovedTrack]
    let transitionSourceID: String?

    init(
      album: ApprovedAlbum,
      tracks: [ApprovedTrack],
      transitionSourceID: String? = nil,
    ) {
      self.album = album
      self.tracks = tracks
      self.transitionSourceID = transitionSourceID
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case playAlbum([PlaybackItem])
      case playTrack(PlaybackItem)
    }

    case playTapped
    case trackTapped(ApprovedTrack.ID)
    case delegate(DelegateAction)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .playTapped:
        let items = state.tracks.map { PlaybackItem(
          track: $0,
          artworkURL: state.album.artworkURL,
          allowsArtwork: state.album.showsArtwork,
        ) }
        guard !items.isEmpty else { return .none }
        return .send(.delegate(.playAlbum(items)))

      case .trackTapped(let trackID):
        guard let track = state.tracks.first(where: { $0.id == trackID }) else { return .none }
        return .send(.delegate(.playTrack(PlaybackItem(
          track: track,
          artworkURL: state.album.artworkURL,
          allowsArtwork: state.album.showsArtwork,
        ))))

      case .delegate:
        return .none
      }
    }
  }
}

extension AlbumDetailFeature.State {
  var pushID: String {
    self.transitionSourceID ?? self.album.id.rawValue
  }
}
