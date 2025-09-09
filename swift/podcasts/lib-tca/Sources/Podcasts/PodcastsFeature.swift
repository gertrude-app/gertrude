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
  }

  enum Action: Equatable {
    case addShowTapped
    case destination(PresentationAction<Destination.Action>)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addShowTapped:
        state.destination = .addShow(.init(passcode: state.passcode))
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
