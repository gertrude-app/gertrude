import ComposableArchitecture
import SharingGRDB
import SwiftUI

@Reducer
struct PodcastsFeature {
  @ObservableState
  struct State: Equatable {
    var passcode: Int
    var shows: [Show]
    @Presents var destination: Destination.State?
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Destination {
    case addShow(AddShowFeature)
    case show(ShowFeature)
  }

  enum Action: Equatable {
    case addShowTapped
    case showTapped(Int)
    case destination(PresentationAction<Destination.Action>)
  }

  @Dependency(\.defaultDatabase) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addShowTapped:
        state.destination = .addShow(.init(passcode: state.passcode))
        return .none

      case .showTapped(let showId):
        guard let show = state.shows.first(where: { $0.id == showId }) else {
          reportIssue("Show with id \(showId) not found")
          return .none
        }
        let episodes = withErrorReporting {
          try self.db.read {
            try Episode.all
              .where { $0.showId == show.id }
              .fetchAll($0)
          }
        }
        state.destination = .show(.init(show: show, episodes: episodes ?? []))
        return .none

      case .destination(.presented(.addShow(.subscribed(let show)))):
        state.shows.append(show)
        state.destination = nil
        return .none

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension PodcastsFeature.State {
  init(passcode: Int) {
    @Dependency(\.defaultDatabase) var db

    var shows: [Show] = []
    withErrorReporting {
      try db.read {
        shows = try Show.all.fetchAll($0)
      }
    }

    self.shows = shows
    self.passcode = passcode
  }
}
