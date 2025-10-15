import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    @Fetch(CurrentSubscription()) var subscription: Subscription = .fallback
  }

  enum Action: Equatable {
    case subscribeNowTapped
  }

  @Dependency(\.date) var date
  @Dependency(\.db) var database
  @Dependency(\.storekit) var storekit

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .subscribeNowTapped:
        .run { [state] _ in
          let result = try await self.storekit.purchaseSubscription()
          switch result {
          case .success(let txn):
            log(.subscription("af0a338f"), "subscribe success", detail: "\(txn)")
            let expiration = txn.expirationDate ?? self.date.now + .days(365)
            try CurrentSubscription.set(status: .active, expiringAt: expiration)
            await self.storekit.finishTransaction(id: txn.id)
          case .unverified(_, let error):
            log(.subscription("d6365993"), "purchase unverified", detail: error)
          case .userCancelled:
            log(.subscription("9c0c89e7"), "purchase cancelled by user")
          case .pending where state.subscription.status == .trialing,
               .pending where state.subscription.status == .unpaid:
            log(.subscription("41eb271c"), "purchase pending")
            self.database.tryWrite { db in
              try Subscription
                .update { $0.purchasePendingSince = self.date.now }
                .execute(db)
            }
          case .pending:
            log(.unexpected("da908c74"), "purchase pending unexpected state")
          case .unknown:
            log(.unexpected("54078374"), "purchase unknown result", detail: "\(result)")
          }
        }
      }
    }
  }
}
