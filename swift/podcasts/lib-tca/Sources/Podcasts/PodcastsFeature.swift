import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct PodcastsFeature {
  @ObservableState
  struct State: Equatable {
    var passcode: Int
    @FetchAll(Show.orderedWithInfo, animation: .default)
    var shows: [ShowInfo]
    var downloadQueue: [Episode] = []
    @Presents var destination: Destination.State?
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
    case confirm(ConfirmationDialogState<ConfirmAction>)
  }

  enum Action: Equatable {
    case onAppear
    case addShowTapped
    case settingsTapped
    case debugMenuTapped(PodcastsHomeView.DebugMenuAction)
    case startNextDownload
    case addToDownloadQueue([Episode])
    case showTapped(Show.ID)
    case deleteShowTapped(Show.ID)
    case destination(PresentationAction<Destination.Action>)
  }

  enum ConfirmAction: Equatable {
    case confirmDelete(show: Show.ID)
    case confirmTrialEnding
  }

  @Dependency(\.db) var database
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        self.maybeShowTrialEndingDialogue(state: &state)
        return .run { send in
          await self.updateFeedsAndDownload(with: send)
          for await _ in self.clock.timer(interval: .seconds(60 * 5)) {
            await self.updateFeedsAndDownload(with: send)
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

      case .debugMenuTapped(let action):
        return self.handleDebugMenu(action)

      case .showTapped(let showId):
        guard let show = self.database.show(id: showId) else {
          unexpected(id: "62c1d0f4", assert: true)
          return .none
        }
        state.destination = .show(.init(show: show))
        return .none

      case .deleteShowTapped(let showId):
        state.destination = .confirm(
          .init(titleVisibility: .visible) {
            TextState("Delete this show and all its episodes?")
          } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(show: showId)) {
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
            .order { ($0.pubDate.desc(), $0.episodeNumber.desc()) }
            .limit(3)
            .fetchAll($0)
        }.reversed()
        return .send(.startNextDownload)

      case .destination(.presented(.confirm(.confirmDelete(show: let showId)))):
        state.destination = nil
        return .run { send in
          removeShowLocalFilesDir(id: showId)
          self.database.tryWrite { db in
            try Show.find(showId).delete().execute(db)
          }
        }

      case .destination(.presented(.confirm(.confirmTrialEnding))):
        state.destination = .settings(.init())
        return .none

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

  func queryShows() -> [ShowInfo] {
    self.database.tryRead {
      try Show.orderedWithInfo.fetchAll($0)
    }
  }

  func maybeShowTrialEndingDialogue(state: inout State) {
    if state.subscription.status == .trialing,
       state.subscription.expiresAt.timeIntervalSince(self.date.now) <= .days(5),
       self.database.record(id: .trialEndingAlertShown) == nil {
      state.destination = .confirm(
        .init(titleVisibility: .visible) {
          TextState("Your free trial is ending soon!")
        } actions: {
          ButtonState(action: .confirmTrialEnding) {
            TextState("Subscribe now")
          }
          ButtonState(role: .cancel) {
            TextState("Dismiss")
          }
        } message: {
          TextState("Subscribe to continue using the app.")
        }
      )
      self.database.tryWrite { db in
        try Record
          .insert { Record(id: .trialEndingAlertShown, value: "true") }
          .execute(db)
      }
    }
  }

  @MainActor
  func updateFeedsAndDownload(with send: Send<Action>) async {
    let downloads = await updateFeeds()
    if !downloads.isEmpty {
      send(.addToDownloadQueue(downloads))
    }
  }

  func handleDebugMenu(_ action: PodcastsHomeView.DebugMenuAction) -> Effect<Action> {
    switch action {
    case .setTrialExpiringSoon:
      .run { _ in
        try CurrentSubscription.set(status: .trialing, expiringAt: self.date.now + .days(3))
      }
    case .setUnpaid:
      .run { _ in
        try CurrentSubscription.set(status: .unpaid, expiringAt: self.date.now - .days(3))
      }
    case .setActive:
      .run { _ in
        try CurrentSubscription.set(status: .active, expiringAt: self.date.now + .days(186))
      }
    }
  }
}
