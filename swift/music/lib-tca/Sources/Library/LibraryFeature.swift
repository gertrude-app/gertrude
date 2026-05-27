import ComposableArchitecture

@Reducer
struct LibraryFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var status = Status.loading
    @Presents var destination: Destination.State?
  }

  enum Status: Equatable {
    case loading
    case loaded(ApprovedMusicLibrary)
    case empty
    case failed
  }

  @Reducer
  enum Destination {
    case albums(AlbumListFeature)
    case album(AlbumDetailFeature)
    case artists(ArtistListFeature)
    case artist(PlaceholderScreenFeature)
    case tracks(PlaceholderScreenFeature)
    case track(PlaceholderScreenFeature)
  }

  enum Action: Equatable {
    case onAppear
    case approvedLibraryLoaded(ApprovedMusicLibrary)
    case approvedLibraryLoadFailed
    case albumsTitleTapped
    case albumTapped(ApprovedAlbum.ID)
    case albumDetailDismissed(String)
    case artistsTitleTapped
    case artistTapped(ApprovedArtist.ID)
    case tracksTitleTapped
    case trackTapped(ApprovedTrack.ID)
    case delegate(AlbumDetailFeature.Action.DelegateAction)
    case destination(PresentationAction<Destination.Action>)
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
        state.status = library.isEmpty ? .empty : .loaded(library)
        return .none

      case .approvedLibraryLoadFailed:
        state.status = .failed
        return .none

      case .albumsTitleTapped:
        state.destination = .albums(.init(
          albums: self.albums(in: state),
          tracks: self.tracks(in: state),
        ))
        return .none

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

      case .artistsTitleTapped:
        state.destination = .artists(.init(artists: self.artists(in: state)))
        return .none

      case .artistTapped(let artistID):
        state.destination = .artist(.init(
          title: self.artistName(artistID, in: state),
          transitionSourceID: artistID.rawValue,
        ))
        return .none

      case .tracksTitleTapped:
        state.destination = .tracks(.init(title: "Tracks"))
        return .none

      case .trackTapped(let trackID):
        state.destination = .track(.init(
          title: self.trackTitle(trackID, in: state),
          transitionSourceID: trackID.rawValue,
        ))
        return .none

      case .destination(.presented(.album(.delegate(let delegateAction)))),
           .destination(.presented(.albums(.delegate(let delegateAction)))):
        return .send(.delegate(delegateAction))

      case .delegate, .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }

  private func albums(in state: State) -> [ApprovedAlbum] {
    guard case .loaded(let library) = state.status else { return [] }
    return library.albums
  }

  private func artists(in state: State) -> [ApprovedArtist] {
    guard case .loaded(let library) = state.status else { return [] }
    return library.artists
  }

  private func tracks(in state: State) -> [ApprovedTrack] {
    guard case .loaded(let library) = state.status else { return [] }
    return library.tracks
  }

  private func albumDetail(_ albumID: ApprovedAlbum.ID, in state: State) -> AlbumDetailFeature.State? {
    guard case .loaded(let library) = state.status,
          let album = library.album(id: albumID)
    else { return nil }

    return .init(
      album: album,
      tracks: library.tracks(for: album),
      transitionSourceID: albumID.rawValue,
    )
  }

  private func artistName(_ artistID: ApprovedArtist.ID, in state: State) -> String {
    guard case .loaded(let library) = state.status else { return "Artist" }
    return library.artist(id: artistID)?.name ?? "Artist"
  }

  private func trackTitle(_ trackID: ApprovedTrack.ID, in state: State) -> String {
    guard case .loaded(let library) = state.status else { return "Track" }
    return library.track(id: trackID)?.title ?? "Track"
  }
}

extension LibraryFeature.Destination.State: Equatable {}
extension LibraryFeature.Destination.Action: Equatable {}
