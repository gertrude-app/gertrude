import ComposableArchitecture
import SharingGRDB
import SwiftUI

@Reducer
struct PodcastsFeature: Downloader {
  @ObservableState
  struct State: Equatable {
    var passcode: Int
    var shows: [Show]
    var downloadQueue: [Episode] = []
    @Presents var destination: Destination.State?
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Destination {
    case addShow(AddShowFeature)
    case show(ShowFeature)
  }

  enum Action: Equatable {
    case addShowTapped
    case startNextDownload
    case showTapped(Int)
    case destination(PresentationAction<Destination.Action>)
  }

  @Dependency(\.defaultDatabase) var db
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.date) var date

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
        state.destination = .show(.init(show: show))
        return .none

      case .destination(.presented(.addShow(.subscribed(let show)))):
        state.shows.append(show)
        state.destination = nil
        state.downloadQueue += self.db.tryRead {
          try Episode.all
            .where { $0.showId == show.id }
            .order { ($0.episodeNumber.desc(), $0.pubDate.desc()) }
            .limit(3)
            .fetchAll($0)
        }.reversed()
        return .send(.startNextDownload)

      case .startNextDownload:
        guard let episode = state.downloadQueue.popLast() else {
          return .none
        }
        return .run { send in
          await self.trackedDownload(episode: episode)
          await send(.startNextDownload)
        }

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
    self.shows = db.tryRead { try Show.all.fetchAll($0) }
    self.passcode = passcode
  }
}
