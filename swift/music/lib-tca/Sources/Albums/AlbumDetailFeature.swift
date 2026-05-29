import ComposableArchitecture

@Reducer
struct AlbumDetailFeature {
  @ObservableState
  struct State: Equatable {
    let album: ApprovedAlbum
    let tracks: [ApprovedTrack]
    let transitionSourceID: String?
    var playStatus: PlaybackFeature.PlayStatus?
    var currentTrackID: ApprovedTrack.ID?

    init(
      album: ApprovedAlbum,
      tracks: [ApprovedTrack],
      transitionSourceID: String? = nil,
      playStatus: PlaybackFeature.PlayStatus? = nil,
      currentTrackID: ApprovedTrack.ID? = nil,
    ) {
      self.album = album
      self.tracks = tracks
      self.transitionSourceID = transitionSourceID
      self.playStatus = playStatus
      self.currentTrackID = currentTrackID
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case playAlbum(items: [PlaybackItem], startIndex: Int)
      case togglePlayPause
    }

    case playTapped
    case trackTapped(ApprovedTrack.ID)
    case delegate(DelegateAction)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .playTapped:
        if state.currentTrackID != nil {
          return .send(.delegate(.togglePlayPause))
        }

        let items = state.playbackItems
        guard !items.isEmpty else { return .none }
        return .send(.delegate(.playAlbum(items: items, startIndex: 0)))

      case .trackTapped(let trackID):
        guard let startIndex = state.tracks.firstIndex(where: { $0.id == trackID }) else { return .none }
        if state.currentTrackID == trackID {
          return .send(.delegate(.togglePlayPause))
        }
        return .send(.delegate(.playAlbum(
          items: state.playbackItems,
          startIndex: startIndex
        )))

      case .delegate:
        return .none
      }
    }
  }
}

extension AlbumDetailFeature.State {
  var isPlaying: Bool {
    self.playStatus == .playing
  }

  var pushID: String {
    self.transitionSourceID ?? self.album.id.rawValue
  }

  var playbackItems: [PlaybackItem] {
    self.tracks.map { PlaybackItem(
      track: $0,
      artworkURL: self.album.artworkURL,
      allowsArtwork: self.album.showsArtwork,
    ) }
  }

  mutating func setPlaybackSession(_ session: PlaybackFeature.Session?) {
    guard let session,
          self.tracks.contains(where: { $0.id == session.currentTrackID })
    else {
      self.playStatus = nil
      self.currentTrackID = nil
      return
    }

    self.playStatus = session.playStatus
    self.currentTrackID = session.currentTrackID
  }
}
