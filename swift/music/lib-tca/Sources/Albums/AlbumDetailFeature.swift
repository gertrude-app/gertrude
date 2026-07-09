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
      case dismissPlaybackFailure
      case playbackFailureActionTapped
      case playAlbum(items: [PlaybackItem], startIndex: Int)
      case togglePlayPause
    }

    case albumTracksLoadFailed(ApprovedAlbum.ID)
    case albumTracksLoaded(ApprovedAlbum.ID, [ApprovedTrack])
    case delegate(DelegateAction)
    case onAppear
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case playTapped
    case trackTapped(ApprovedTrack.ID)
  }

  enum CancelID: Hashable {
    case albumTracks
  }

  @Dependency(\.approvedMusic) var approvedMusic

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
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

      case .playTapped:
        if state.currentTrackID != nil {
          return .send(.delegate(.togglePlayPause))
        }

        let items = state.playbackItems
        guard !items.isEmpty else {
          return self.loadTracksIfNeeded(&state)
        }
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

  var pushID: String {
    self.transitionSourceID ?? self.album.id.rawValue
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
