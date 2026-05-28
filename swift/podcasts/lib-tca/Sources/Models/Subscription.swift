import Foundation
import LibViews
import PodcastRoute
import SQLiteData
import Tagged

@Table("subscription")
struct Subscription: Equatable {
  typealias ID = Tagged<Self, Int>
  let id: ID
  var status: Status
  var purchasePendingSince: Date?
  var expiresAt: Date
  var updatedAt: Date = .init()
  var createdAt: Date = .init()
}

extension Subscription {
  enum Status: String, QueryBindable {
    case trialing
    case active
    case complimentary
    case unpaid
  }

  func trialEndingSoon(now: Date = .init()) -> Bool {
    guard self.status == .trialing else { return false }
    return self.expiresAt <= now + .days(5)
  }
}

extension Subscription {
  static let fallback = Subscription(
    id: 1,
    status: .trialing,
    purchasePendingSince: nil,
    expiresAt: .now + .days(10),
    updatedAt: .now,
    createdAt: .now,
  )

  var settingsViewStatus: SettingsView.SubscriptionStatus {
    switch self.status {
    case .trialing: .trialing(purchasePending: self.purchasePendingSince != nil)
    case .active: .active
    case .complimentary: .complimentary
    case .unpaid: .unpaid(purchasePending: self.purchasePendingSince != nil)
    }
  }

  var homeViewStatus: PodcastsHomeView.SubscriptionStatus {
    if self.status == .unpaid {
      .unpaid
    } else if self.trialEndingSoon() {
      .trialEndingSoon
    } else {
      .ok
    }
  }
}

extension AmSubscriptionState {
  func toLocal(now: Date) -> (status: Subscription.Status, expiresAt: Date) {
    switch self {
    case .complimentary:
      (.complimentary, now + .days(365 * 100))
    case .active(let expiresAt):
      (.active, expiresAt)
    case .fullTrial(let expiresAt), .amTrial(let expiresAt):
      (.trialing, expiresAt)
    case .legacyGrandfathered(let accessEndsAt, _, _):
      (.active, accessEndsAt)
    case .unpaid, .legacyExpired:
      (.unpaid, now)
    }
  }
}

struct CurrentSubscription: FetchKeyRequest {
  typealias Value = Subscription

  func fetch(_ db: Database) throws -> Value {
    let subscription = try Subscription
      .where { $0.id.eq(Subscription.ID(1)) }
      .fetchOne(db)
    guard let subscription else {
      log(.unexpected("c47d3e0b"), "missing subscription record")
      return .fallback
    }
    return subscription
  }

  @discardableResult
  static func set(
    status: Subscription.Status,
    purchasePendingSince: Date? = nil,
    expiringAt: Date,
  ) throws -> Subscription {
    dep(\.db).tryWrite { db in
      try Subscription
        .find(Subscription.ID(1))
        .update {
          $0.status = status
          $0.purchasePendingSince = purchasePendingSince
          $0.expiresAt = expiringAt
        }
        .returning { $0.self }
        .fetchOne(db)
    } ?? .fallback
  }
}
