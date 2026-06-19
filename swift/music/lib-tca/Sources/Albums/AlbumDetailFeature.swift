import ComposableArchitecture

@Reducer
struct AlbumDetailFeature {
  @ObservableState
  struct State: Equatable {
    let album: ApprovedAlbum
    let transitionSourceID: String?
    var playStatus: PlaybackFeature.PlayStatus?
    var currentTrackID: ApprovedTrack.ID?
    var playbackFailure: PlaybackFailure?

    init(
      album: ApprovedAlbum,
      transitionSourceID: String? = nil,
      playStatus: PlaybackFeature.PlayStatus? = nil,
      currentTrackID: ApprovedTrack.ID? = nil,
      playbackFailure: PlaybackFailure? = nil,
    ) {
      self.album = album
      self.transitionSourceID = transitionSourceID
      self.playStatus = playStatus
      self.currentTrackID = currentTrackID
      self.playbackFailure = playbackFailure
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case dismissPlaybackFailure
      case playbackFailureActionTapped
      case playAlbum(items: [PlaybackItem], startIndex: Int)
      case togglePlayPause
    }

    case delegate(DelegateAction)
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case playTapped
    case trackTapped(ApprovedTrack.ID)
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
        guard let startIndex = state.tracks.firstIndex(where: { $0.id == trackID })
        else { return .none }
        if state.currentTrackID == trackID {
          return .send(.delegate(.togglePlayPause))
        }
        return .send(.delegate(.playAlbum(
          items: state.playbackItems,
          startIndex: startIndex,
        )))

      case .playbackFailureDismissed:
        return .send(.delegate(.dismissPlaybackFailure))

      case .playbackFailureActionTapped:
        return .send(.delegate(.playbackFailureActionTapped))

      case .delegate:
        return .none
      }
    }
  }
}

extension AlbumDetailFeature.State {
  var tracks: [ApprovedTrack] {
    self.album.tracks
  }

  var isPlaying: Bool {
    self.playStatus == .playing
  }

  var isLoading: Bool {
    self.playStatus == .loading
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

  mutating func setPlaybackFailure(_ failure: PlaybackFailure?) {
    self.playbackFailure = failure
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
