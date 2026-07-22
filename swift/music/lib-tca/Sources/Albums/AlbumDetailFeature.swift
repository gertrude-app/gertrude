import ComposableArchitecture

@Reducer
struct AlbumDetailFeature {
  @ObservableState
  struct State: Equatable {
    var album: ApprovedAlbum
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
      case addAlbumToPlaylist(ApprovedAlbum.ID)
      case addToQueue(items: [PlaybackItem])
      case dismissPlaybackFailure
      case playbackFailureActionTapped
      case playNow(items: [PlaybackItem], startIndex: Int)
      case playNext(items: [PlaybackItem])
      case togglePlayPause
      case addTrackToPlaylist(trackID: ApprovedTrack.ID, albumID: ApprovedAlbum.ID)
    }

    case addToPlaylistTapped
    case addToQueueTapped
    case delegate(DelegateAction)
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case playNextTapped
    case playTapped
    case trackAddToPlaylistTapped(ApprovedTrack.ID)
    case trackAddToQueueTapped(ApprovedTrack.ID)
    case trackPlayNextTapped(ApprovedTrack.ID)
    case trackTapped(ApprovedTrack.ID)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addToPlaylistTapped:
        return .send(.delegate(.addAlbumToPlaylist(state.album.id)))

      case .addToQueueTapped:
        guard !state.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.addToQueue(items: state.playbackItems)))

      case .playNextTapped:
        guard !state.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.playNext(items: state.playbackItems)))

      case .playTapped:
        if state.currentTrackID != nil {
          return .send(.delegate(.togglePlayPause))
        }

        let items = state.playbackItems
        guard !items.isEmpty else { return .none }
        return .send(.delegate(.playNow(items: items, startIndex: 0)))

      case .trackAddToPlaylistTapped(let trackID):
        guard state.tracks.contains(where: { $0.id == trackID }) else { return .none }
        return .send(.delegate(.addTrackToPlaylist(
          trackID: trackID,
          albumID: state.album.id,
        )))

      case .trackAddToQueueTapped(let trackID):
        guard let item = state.playbackItems.first(where: { $0.id == trackID })
        else { return .none }
        return .send(.delegate(.addToQueue(items: [item])))

      case .trackPlayNextTapped(let trackID):
        guard let item = state.playbackItems.first(where: { $0.id == trackID })
        else { return .none }
        return .send(.delegate(.playNext(items: [item])))

      case .trackTapped(let trackID):
        guard let startIndex = state.tracks.firstIndex(where: { $0.id == trackID })
        else { return .none }
        if state.currentTrackID == trackID {
          return .send(.delegate(.togglePlayPause))
        }
        return .send(.delegate(.playNow(
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

  var playbackItems: [PlaybackItem] {
    self.tracks.map { PlaybackItem(
      track: $0,
      artworkURL: self.album.artworkURL,
      albumID: self.album.id,
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
