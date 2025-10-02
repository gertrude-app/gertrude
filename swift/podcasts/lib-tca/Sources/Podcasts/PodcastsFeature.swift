import ComposableArchitecture
import SharingGRDB
import SwiftUI

@Reducer
struct PodcastsFeature: Downloader {
  @ObservableState
  struct State: Equatable {
    var passcode: Int
    var downloadQueue: [Episode] = []
    @Presents var destination: Destination.State?

    @FetchAll(
      #sql("""
      SELECT
        \(Show.col.id), \(Show.col.name), \(Show.col.author),
        \(Show.col.description), \(Show.col.showArtwork), \(Show.col.artworkUrl),
        COALESCE(COUNT(\(Episode.col.id)), 0) AS totalEpisodes,
        COALESCE(SUM(CASE WHEN \(Episode.col.completedAt) IS NULL
          THEN 1 ELSE 0 END), 0) AS unplayedEpisodes,
        MAX(\(Episode.col.pubDate)) AS mostRecentPubDate
      FROM \(Show.self)
      LEFT JOIN \(Episode.self) ON \(Episode.col.showId) = \(Show.col.id)
      GROUP BY \(Show.col.id), \(Show.col.name), \(Show.col.author), \(Show.col.artworkUrl)
      ORDER BY mostRecentPubDate DESC;
      """)
    ) var shows: [ShowInfo]
  }

  @Selection
  struct ShowInfo: Equatable {
    let id: Show.ID
    let name: String
    let author: String?
    let description: String?
    let showArtwork: Bool
    let artworkUrl: String?
    let totalEpisodes: Int
    let unplayedEpisodes: Int
    let mostRecentPubDate: Date?
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Destination {
    case addShow(AddShowFeature)
    case show(ShowFeature)
  }

  enum Action: Equatable {
    case onAppear
    case addShowTapped
    case startNextDownload
    case addToDownloadQueue([Episode])
    case showTapped(Show.ID)
    case destination(PresentationAction<Destination.Action>)
  }

  @Dependency(\.defaultDatabase) var database
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          await send(.addToDownloadQueue(updateFeeds()))
          for await _ in self.clock.timer(interval: .seconds(60 * 5)) {
            await send(.addToDownloadQueue(updateFeeds()))
          }
        }

      case .addShowTapped:
        state.destination = .addShow(.init(passcode: state.passcode))
        return .none

      case .showTapped(let showId):
        guard let show = self.database.show(id: showId) else {
          unexpected(id: "62c1d0f4", assert: true)
          return .none
        }
        state.destination = .show(.init(show: show))
        return .none

      case .destination(.presented(.addShow(.subscribed(let show)))):
        state.destination = nil
        state.downloadQueue += self.database.tryRead {
          try Episode.all
            .where { $0.showId == show.id }
            .order { ($0.episodeNumber.desc(), $0.pubDate.desc()) }
            .limit(3)
            .fetchAll($0)
        }.reversed()
        return .send(.startNextDownload)

      case .addToDownloadQueue(let episodes):
        state.downloadQueue += episodes
        return state.downloadQueue.isEmpty ? .none : .send(.startNextDownload)

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
