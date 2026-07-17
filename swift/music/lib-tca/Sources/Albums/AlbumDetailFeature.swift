import ComposableArchitecture

@Reducer
struct AlbumDetailFeature {
  @ObservableState
  struct State: Equatable {
    var album: ApprovedAlbum
    let transitionSourceID: String?
    var playStatus: PlaybackFeature.PlayStatus?
    var currentTrackID: ApprovedTrack.ID?
    var isLoadingTracks = false
    var playbackFailure: PlaybackFailure?

    init(
      album: ApprovedAlbum,
      transitionSourceID: String? = nil,
      playStatus: PlaybackFeature.PlayStatus? = nil,
      currentTrackID: ApprovedTrack.ID? = nil,
      isLoadingTracks: Bool = false,
      playbackFailure: PlaybackFailure? = nil,
    ) {
      self.album = album
      self.transitionSourceID = transitionSourceID
      self.playStatus = playStatus
      self.currentTrackID = currentTrackID
      self.isLoadingTracks = isLoadingTracks
      self.playbackFailure = playbackFailure
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case addToQueue(items: [PlaybackItem])
      case dismissPlaybackFailure
      case playbackFailureActionTapped
      case playNow(items: [PlaybackItem], startIndex: Int)
      case playNext(items: [PlaybackItem])
      case togglePlayPause
    }

    case addToQueueTapped
    case albumTracksLoadFailed(ApprovedAlbum.ID)
    case albumTracksLoaded(ApprovedAlbum.ID, [ApprovedTrack])
    case delegate(DelegateAction)
    case onAppear
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case playNextTapped
    case playTapped
    case trackAddToQueueTapped(ApprovedTrack.ID)
    case trackPlayNextTapped(ApprovedTrack.ID)
    case trackTapped(ApprovedTrack.ID)
  }

  enum CancelID: Hashable {
    case albumTracks
  }

  @Dependency(\.approvedMusic) var approvedMusic

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addToQueueTapped:
        guard !state.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.addToQueue(items: state.playbackItems)))

      case .onAppear:
        return self.loadTracksIfNeeded(&state)

      case .albumTracksLoaded(let albumID, let tracks):
        guard state.album.id == albumID else { return .none }
        state.album.tracks = tracks
        state.isLoadingTracks = false
        return .none

      case .albumTracksLoadFailed(let albumID):
        guard state.album.id == albumID else { return .none }
        state.isLoadingTracks = false
        return .none

      case .playNextTapped:
        guard !state.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.playNext(items: state.playbackItems)))

      case .playTapped:
        if state.currentTrackID != nil {
          return .send(.delegate(.togglePlayPause))
        }

        let items = state.playbackItems
        guard !items.isEmpty else {
          return self.loadTracksIfNeeded(&state)
        }
        return .send(.delegate(.playNow(items: items, startIndex: 0)))

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

  private func loadTracksIfNeeded(_ state: inout State) -> EffectOf<Self> {
    guard state.album.tracks.isEmpty, !state.isLoadingTracks else { return .none }
    state.isLoadingTracks = true
    let albumID = state.album.id
    return .run { send in
      do {
        let tracks = try await self.approvedMusic.loadAlbumTracks(albumID)
        await send(.albumTracksLoaded(albumID, tracks))
      } catch {
        await send(.albumTracksLoadFailed(albumID))
      }
    }
    .cancellable(id: CancelID.albumTracks, cancelInFlight: true)
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
