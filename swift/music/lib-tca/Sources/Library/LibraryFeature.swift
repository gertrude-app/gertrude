import ComposableArchitecture

@Reducer
struct LibraryFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var status = Status.loading
    @Presents var albumDetail: AlbumDetailFeature.State?
  }

  enum Status: Equatable {
    case loading
    case loaded(ApprovedMusicLibrary)
    case empty
    case failed
  }

  enum Action: Equatable {
    case onAppear
    case approvedLibraryLoaded(ApprovedMusicLibrary)
    case approvedLibraryLoadFailed
    case albumTapped(ApprovedAlbum.ID)
    case albumDetailDismissed(String)
    case delegate(AlbumDetailFeature.Action.DelegateAction)
    case albumDetail(PresentationAction<AlbumDetailFeature.Action>)
  }

  @Dependency(\.approvedMusic) var approvedMusic

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.status = .loading
        return .run { send in
          do {
            await send(.approvedLibraryLoaded(try await self.approvedMusic.loadApprovedLibrary()))
          } catch {
            await send(.approvedLibraryLoadFailed)
          }
        }

      case .approvedLibraryLoaded(let library):
        state.status = library.albums.isEmpty ? .empty : .loaded(library)
        return .none

      case .approvedLibraryLoadFailed:
        state.status = .failed
        return .none

      case .albumTapped(let albumID):
        state.albumDetail = self.albumDetail(albumID, in: state)
        return .none

      case .albumDetailDismissed(let pushID):
        guard state.albumDetail?.pushID == pushID else { return .none }
        state.albumDetail = nil
        return .none

      case .albumDetail(.presented(.delegate(let delegateAction))):
        return .send(.delegate(delegateAction))

      case .delegate, .albumDetail:
        return .none
      }
    }
    .ifLet(\.$albumDetail, action: \.albumDetail) {
      AlbumDetailFeature()
    }
  }

  private func albumDetail(_ albumID: ApprovedAlbum.ID, in state: State) -> AlbumDetailFeature
    .State?
  {
    guard case .loaded(let library) = state.status,
      let album = library.album(id: albumID)
    else { return nil }

    return .init(
      album: album,
      tracks: library.tracks(for: album),
      transitionSourceID: albumID.rawValue,
    )
  }
}

extension LibraryFeature.State {
  mutating func setAlbumDetailPlaybackSession(_ session: PlaybackFeature.Session?) {
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackSession(session)
    self.albumDetail = albumDetail
  }
}
