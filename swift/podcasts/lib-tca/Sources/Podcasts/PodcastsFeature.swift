import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct PodcastsFeature {
  @ObservableState
  struct State: Equatable {
    @FetchAll(Show.orderedWithInfo, animation: .default)
    var shows: [ShowInfo]
    var downloadQueue: [Episode] = []
    @Presents var destination: Destination.State?
    @Fetch(CurrentSubscription()) var subscription: Subscription = .fallback
    var isClaimed = false
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

  @Reducer
  enum Destination {
    case addShow(AddShowFeature)
    case show(ShowFeature)
    case settings(SettingsFeature)
    case confirm(ConfirmationDialogState<ConfirmAction>)
    case requestReview(AppStoreReviewFeature)
  }

  enum Action: Equatable {
    case onAppear
    case addShowTapped
    case settingsTapped
    case promptReview
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

  static let appStoreID = GertrudeIOSApp.podcasts.appStoreAppleId

  @Dependency(\.db) var database
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date
  @Dependency(\.keychain) var keychain

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isClaimed = self.keychain.isClaimed()
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
          state.destination = .addShow(.init())
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
            TextState(lstr(.podcastsDeleteConfirm))
          } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(show: showId)) {
              TextState(lstr(.showsDelete))
            }
            ButtonState(role: .cancel) {
              TextState(lstr(.pinCancel))
            }
          } message: {
            TextState(lstr(.podcastsDeleteWarning))
          },
        )
        return .none

      case .destination(.presented(.addShow(.subscribed(let show)))):
        state.destination = nil
        state.downloadQueue += self.database.tryRead {
          try Episode.all
            .where { $0.showId.eq(show.id) }
            .order { ($0.pubDate.desc(), $0.episodeNumber.desc()) }
            .limit(3)
            .fetchAll($0)
        }.reversed()
        return .run { send in
          await send(.startNextDownload)
          guard self.database.tryRead({ try Show.count().fetchOne($0) }) == 4,
                self.database.record(id: .promptedReview) == nil else { return }
          self.database.insertRecord(id: .promptedReview)
          try? await self.clock.sleep(for: .seconds(1.5))
          await send(.promptReview)
        }

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

      case .destination(.presented(.settings(.delegate(.changePinRequested)))):
        state.destination = .addShow(.init(screen: .changePinInstructions))
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

      case .promptReview:
        state.destination = .requestReview(.init(appStoreID: Self.appStoreID))
        return .none

      case .destination(.presented(.requestReview(.giveRatingButtonTapped))):
        log(.info, .review, "71393f94")
        return .none

      case .destination(.presented(.requestReview(.leaveReviewButtonTapped))):
        log(.info, .review, "b96de934")
        return .none

      case .destination(.presented(.requestReview(.noThanksButtonTapped))):
        log(.info, .review, "ecef1f7f")
        return .none

      case .destination(.dismiss):
        state.isClaimed = self.keychain.isClaimed()
        return .none

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }

  func maybeShowTrialEndingDialogue(state: inout State) {
    if state.subscription.status == .trialing,
       state.subscription.expiresAt.timeIntervalSince(self.date.now) <= .days(5),
       self.database.record(id: .trialEndingAlertShown) == nil {
      state.destination = .confirm(
        .init(titleVisibility: .visible) {
          TextState(lstr(.trialAlertTitle))
        } actions: {
          ButtonState(action: .confirmTrialEnding) {
            TextState(lstr(.trialAlertSubscribe))
          }
          ButtonState(role: .cancel) {
            TextState(lstr(.claimNotNow))
          }
        } message: {
          TextState(lstr(.trialAlertMessage))
        },
      )
      self.database.insertRecord(id: .trialEndingAlertShown)
    }
  }

  @MainActor
  func updateFeedsAndDownload(with send: SendOf<PodcastsFeature>) async {
    let downloads = await updateFeeds()
    if !downloads.isEmpty {
      send(.addToDownloadQueue(downloads))
    }
  }

  func handleDebugMenu(_ action: PodcastsHomeView.DebugMenuAction) -> EffectOf<PodcastsFeature> {
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

extension PodcastsFeature.Destination.State: Equatable {}
extension PodcastsFeature.Destination.Action: Equatable {}
