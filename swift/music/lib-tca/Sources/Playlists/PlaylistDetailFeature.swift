import ComposableArchitecture

@Reducer
struct PlaylistDetailFeature {
  @ObservableState
  struct State: Equatable {
    var playlist: MusicPlaylist
    var playStatus: PlaybackFeature.PlayStatus?
    var currentEntryID: MusicPlaylistEntry.ID?
    var playbackFailure: PlaybackFailure?

    init(
      playlist: MusicPlaylist,
      playStatus: PlaybackFeature.PlayStatus? = nil,
      currentEntryID: MusicPlaylistEntry.ID? = nil,
      playbackFailure: PlaybackFailure? = nil,
    ) {
      self.playlist = playlist
      self.playStatus = playStatus
      self.currentEntryID = currentEntryID
      self.playbackFailure = playbackFailure
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case addEntryToPlaylist(MusicPlaylistEntry.ID)
      case addMusic
      case addToQueue(items: [PlaybackItem])
      case delete
      case dismissPlaybackFailure
      case playbackFailureActionTapped
      case playNext(items: [PlaybackItem])
      case playNow(items: [PlaybackItem], startIndex: Int)
      case removeEntry(MusicPlaylistEntry.ID)
      case rename(String)
      case reorder([MusicPlaylistEntry.ID])
      case togglePlayPause
    }

    case addMusicTapped
    case addToQueueTapped
    case delegate(DelegateAction)
    case deleteTapped
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case playNextTapped
    case playTapped
    case removeEntryTapped(MusicPlaylistEntry.ID)
    case renameSubmitted(String)
    case reorderSubmitted([MusicPlaylistEntry.ID])
    case trackAddToPlaylistTapped(MusicPlaylistEntry.ID)
    case trackAddToQueueTapped(MusicPlaylistEntry.ID)
    case trackPlayNextTapped(MusicPlaylistEntry.ID)
    case trackTapped(MusicPlaylistEntry.ID)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addMusicTapped:
        return .send(.delegate(.addMusic))

      case .addToQueueTapped:
        guard !state.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.addToQueue(items: state.playbackItems)))

      case .deleteTapped:
        return .send(.delegate(.delete))

      case .playbackFailureActionTapped:
        return .send(.delegate(.playbackFailureActionTapped))

      case .playbackFailureDismissed:
        return .send(.delegate(.dismissPlaybackFailure))

      case .playNextTapped:
        guard !state.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.playNext(items: state.playbackItems)))

      case .playTapped:
        if state.currentEntryID != nil {
          return .send(.delegate(.togglePlayPause))
        }
        guard !state.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.playNow(items: state.playbackItems, startIndex: 0)))

      case .removeEntryTapped(let entryID):
        guard state.playlist.entries.contains(where: { $0.id == entryID }) else { return .none }
        return .send(.delegate(.removeEntry(entryID)))

      case .renameSubmitted(let name):
        return .send(.delegate(.rename(name)))

      case .reorderSubmitted(let entryIDs):
        guard entryIDs.count == state.playlist.entries.count,
              Set(entryIDs) == Set(state.playlist.entries.map(\.id)) else { return .none }
        return .send(.delegate(.reorder(entryIDs)))

      case .trackAddToPlaylistTapped(let entryID):
        guard state.playlist.entries.contains(where: { $0.id == entryID }) else { return .none }
        return .send(.delegate(.addEntryToPlaylist(entryID)))

      case .trackAddToQueueTapped(let entryID):
        guard let item = state.playbackItem(entryID: entryID) else { return .none }
        return .send(.delegate(.addToQueue(items: [item])))

      case .trackPlayNextTapped(let entryID):
        guard let item = state.playbackItem(entryID: entryID) else { return .none }
        return .send(.delegate(.playNext(items: [item])))

      case .trackTapped(let entryID):
        guard let startIndex = state.playlist.entries.firstIndex(where: { $0.id == entryID })
        else { return .none }
        if state.currentEntryID == entryID {
          return .send(.delegate(.togglePlayPause))
        }
        return .send(.delegate(.playNow(items: state.playbackItems, startIndex: startIndex)))

      case .delegate:
        return .none
      }
    }
  }
}

extension PlaylistDetailFeature.State {
  var isPlaying: Bool {
    self.playStatus == .playing
  }

  var isLoading: Bool {
    self.playStatus == .loading
  }

  var playbackItems: [PlaybackItem] {
    self.playlist.entries.map { entry in
      PlaybackItem(
        track: entry.track,
        artworkURL: entry.track.artworkURL,
        albumID: entry.track.albumID,
      )
      .withPlaylistSource(.init(
        playlistID: self.playlist.id.rawValue,
        entryID: entry.id.rawValue,
      ))
    }
  }

  func playbackItem(entryID: MusicPlaylistEntry.ID) -> PlaybackItem? {
    guard let index = self.playlist.entries.firstIndex(where: { $0.id == entryID })
    else { return nil }
    return self.playbackItems[index]
  }

  mutating func setPlaybackFailure(_ failure: PlaybackFailure?) {
    self.playbackFailure = failure
  }

  mutating func setPlaybackSession(_ session: PlaybackFeature.Session?) {
    guard let session,
          let source = session.queue.currentItem.playlistSource,
          source.playlistID == self.playlist.id.rawValue,
          let entryID = self.playlist.entries.first(where: {
            $0.id.rawValue == source.entryID
          })?.id else {
      self.playStatus = nil
      self.currentEntryID = nil
      return
    }
    self.playStatus = session.playStatus
    self.currentEntryID = entryID
  }
}
