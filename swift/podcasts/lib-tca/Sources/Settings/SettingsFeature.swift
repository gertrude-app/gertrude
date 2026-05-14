import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    @Fetch(CurrentSubscription()) var subscription: Subscription = .fallback
    var purchaseInProgress: Bool = false
    var reclaimableBytes: Int = 0
  }

  enum Action: Equatable {
    case view(SettingsView.Event)
    case onAppear
    case finishPurchase
    case delegate(DelegateAction)
  }

  enum DelegateAction: Equatable {
    case changePinRequested
  }

  @Dependency(\.date) var date
  @Dependency(\.db) var database
  @Dependency(\.api) var api
  @Dependency(\.storekit) var storekit

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.reclaimableBytes = self.calculateReclaimableBytes()
        return .none

      case .view(.reclaimStorageTapped):
        self.reclaimAllDownloads()
        state.reclaimableBytes = 0
        return .none

      case .view(.subscribeNowTapped),
           .view(.manageSubscriptionTapped):
        state.purchaseInProgress = true
        let manage = action == .view(.manageSubscriptionTapped) ? "(manage) " : ""
        return .run { [state] send in
          let productIds = try await self.api.productIds()
          switch try await self.storekit.purchaseSubscription(productIds: productIds) {
          case .success(let txn):
            log(.subscription("af0a338f"), "\(manage)subscribe success", detail: "\(txn)")
            let expiration = txn.expirationDate ?? self.date.now + .days(365)
            try CurrentSubscription.set(status: .active, expiringAt: expiration)
            await self.storekit.finishTransaction(id: txn.id)
          case .unverified(_, let error):
            log(.subscription("d6365993"), "\(manage)purchase unverified", detail: error)
          case .userCancelled:
            log(.subscription("9c0c89e7"), "\(manage)purchase cancelled by user")
          case .pending where state.subscription.status == .trialing,
               .pending where state.subscription.status == .unpaid:
            log(.subscription("41eb271c"), "\(manage)purchase pending")
            self.database.tryWrite { db in
              try Subscription
                .update { $0.purchasePendingSince = #bind(self.date.now) }
                .execute(db)
            }
          case .pending:
            log(.unexpected("da908c74"), "\(manage)purchase pending unexpected state")
          case .unknown:
            log(.unexpected("54078374"), "\(manage)purchase unknown result")
          }
          await send(.finishPurchase)
        }

      case .view(.changePinTapped):
        return .send(.delegate(.changePinRequested))

      case .finishPurchase:
        state.purchaseInProgress = false
        return .none

      case .delegate:
        return .none
      }
    }
  }

  func calculateReclaimableBytes() -> Int {
    let nowPlayingId = self.database.nowPlaying()?.episode.id
    let now = self.date.now
    let episodes = self.database.tryRead { db in
      try Episode
        .where { $0.downloadedAt.isNot(nil) }
        .where { #sql("\($0.downloadedAt) < \(now)") }
        .where { if let id = nowPlayingId { $0.id.neq(id) } }
        .fetchAll(db)
    }
    return episodes.reduce(0) { $0 + $1.sizeInBytes }
  }

  func reclaimAllDownloads() {
    let nowPlayingId = self.database.nowPlaying()?.episode.id
    let now = self.date.now
    let episodes = self.database.tryRead { db in
      try Episode
        .where { $0.downloadedAt.isNot(nil) }
        .where { #sql("\($0.downloadedAt) < \(now)") }
        .where { if let id = nowPlayingId { $0.id.neq(id) } }
        .fetchAll(db)
    }
    if episodes.isEmpty { return }
    let bytes = episodes.reduce(0) { $0 + $1.sizeInBytes }
    let discardResult = safelyDiscardEpisodeDownloads(
      episodes.map(\.id),
      source: .reclaimStorage,
    )
    log(
      .info("ad696f72"),
      "reclaim storage",
      detail: "requestedEpisodes:\(episodes.count) invalidatedEpisodes:\(discardResult.invalidatedEpisodes.count) protectedEpisodes:\(discardResult.protectedEpisodeIds.count) requestedBytes:\(bytes) invalidatedBytes:\(discardResult.invalidatedEpisodes.reduce(0) { $0 + $1.sizeInBytes })",
    )
  }
}
