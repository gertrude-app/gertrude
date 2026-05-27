import ComposableArchitecture

@Reducer
struct ArtistListFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    let artists: [ApprovedArtist]
    @Presents var destination: Destination.State?

    init(
      artists: [ApprovedArtist],
      destination: Destination.State? = nil,
    ) {
      self.artists = artists
      self.destination = destination
    }
  }

  @Reducer
  enum Destination {
    case artist(PlaceholderScreenFeature)
  }

  enum Action: Equatable {
    case artistTapped(ApprovedArtist.ID)
    case destination(PresentationAction<Destination.Action>)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .artistTapped(let artistID):
        state.destination = .artist(.init(
          title: self.artistName(artistID, in: state),
          transitionSourceID: artistID.rawValue,
        ))
        return .none

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }

  private func artistName(_ artistID: ApprovedArtist.ID, in state: State) -> String {
    ApprovedMusicLibrary(artists: state.artists).artist(id: artistID)?.name ?? "Artist"
  }
}

extension ArtistListFeature.Destination.State: Equatable {}
extension ArtistListFeature.Destination.Action: Equatable {}
