import ComposableArchitecture
import SQLiteData
import SwiftUI

@Reducer
struct PodcastsFeature {
  @ObservableState
  struct State: Equatable {
    var passcode: Int
    var downloadQueue: [Episode] = []
    @Presents var destination: Destination.State?
    @FetchAll(Show.orderedWithInfo, animation: .default)
    var shows: [ShowInfo]
    @Fetch(CurrentSubscription()) var subscription: Subscription = .fallback
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
    case settings(SettingsFeature)
    case confirmDeleteShow(ConfirmationDialogState<ConfirmDeleteAction>)
  }

  enum Action: Equatable {
    case onAppear
    case addShowTapped
    case settingsTapped
    case startNextDownload
    case addToDownloadQueue([Episode])
    case showTapped(Show.ID)
    case deleteShowTapped(Show.ID)
    case destination(PresentationAction<Destination.Action>)
  }

  enum ConfirmDeleteAction: Equatable {
    case confirmDelete(Show.ID)
  }

  @Dependency(\.db) var database
  @Dependency(\.continuousClock) var clock

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
        if state.subscription.status == .unpaid {
          state.destination = .settings(.init())
        } else {
          state.destination = .addShow(.init(passcode: state.passcode))
        }
        return .none

      case .settingsTapped:
        state.destination = .settings(.init())
        return .none

      case .showTapped(let showId):
        guard let show = self.database.show(id: showId) else {
          unexpected(id: "62c1d0f4", assert: true)
          return .none
        }
        state.destination = .show(.init(show: show))
        return .none

      case .deleteShowTapped(let showId):
        state.destination = .confirmDeleteShow(
          .init(titleVisibility: .visible) {
            TextState("Delete this show and all its episodes?")
          } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(showId)) {
              TextState("Delete")
            }
            ButtonState(role: .cancel) {
              TextState("Cancel")
            }
          } message: {
            TextState("This action cannot be undone.")
          }
        )
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

      case .destination(.presented(.confirmDeleteShow(.confirmDelete(let showId)))):
        state.destination = nil
        return .run { _ in
          removeShowLocalFilesDir(id: showId)
          self.database.tryWrite { db in
            try Show.find(showId).delete().execute(db)
          }
        }

      case .addToDownloadQueue(let episodes):
        state.downloadQueue += episodes
        return state.downloadQueue.isEmpty ? .none : .send(.startNextDownload)

      case .startNextDownload:
        guard let episode = state.downloadQueue.popLast() else {
          return .none
        }
        return .run { send in
          _ = await trackedDownload(episode: episode)
          await send(.startNextDownload)
        }

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}
