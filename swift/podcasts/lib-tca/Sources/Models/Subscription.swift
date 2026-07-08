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
  var expiresAt: Date
  var legacyMigrationNag: Bool = false
  var updatedAt: Date = .init()
  var createdAt: Date = .init()
}

extension Subscription {
  enum Status: String, QueryBindable {
    case trialing
    case active
    case legacy
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
    expiresAt: .now + .days(10),
    legacyMigrationNag: false,
    updatedAt: .now,
    createdAt: .now,
  )

  var settingsViewStatus: SettingsView.SubscriptionStatus {
    switch self.status {
    case .trialing: .trialing
    case .active: .active
    case .legacy: .legacy
    case .complimentary: .complimentary
    case .unpaid: .unpaid
    }
  }

  var homeViewStatus: PodcastsHomeView.SubscriptionStatus {
    if self.status == .unpaid {
      .unpaid
    } else if self.legacyMigrationNag {
      .legacyNag(accessEndsAt: self.expiresAt)
    } else if self.trialEndingSoon() {
      .trialEndingSoon
    } else {
      .ok
    }
  }
}

extension AmSubscriptionState {
  func toLocal(now: Date)
    -> (status: Subscription.Status, expiresAt: Date, legacyMigrationNag: Bool) {
    switch self {
    case .complimentary:
      (.complimentary, now + .days(365 * 100), false)
    case .active(let expiresAt):
      (.active, expiresAt, false)
    case .fullTrial(let expiresAt), .amTrial(let expiresAt):
      (.trialing, expiresAt, false)
    case .legacyGrandfathered(let accessEndsAt, let showMigrationNag, _):
      (.legacy, accessEndsAt, showMigrationNag)
    case .unpaid, .legacyExpired:
      (.unpaid, now, false)
    }
  }

  var isEntitled: Bool {
    switch self {
    case .active, .complimentary, .legacyGrandfathered, .fullTrial, .amTrial:
      true
    case .unpaid, .legacyExpired:
      false
    }
  }

  var claimSuccessEntitlement: ClaimSuccessView.Entitlement? {
    switch self {
    case .active: .paid
    case .fullTrial, .amTrial: .trial
    case .complimentary: .complimentary
    case .legacyGrandfathered: .legacy
    case .unpaid, .legacyExpired: nil
    }
  }

  @discardableResult
  func writeLocal(now: Date) -> Subscription {
    let mapped = self.toLocal(now: now)
    return (try? CurrentSubscription.set(
      status: mapped.status,
      expiringAt: mapped.expiresAt,
      legacyMigrationNag: mapped.legacyMigrationNag,
    )) ?? .fallback
  }
}

struct CurrentSubscription: FetchKeyRequest {
  typealias Value = Subscription

  func fetch(_ db: Database) throws -> Value {
    let subscription = try Subscription
      .where { $0.id.eq(Subscription.ID(1)) }
      .fetchOne(db)
    guard let subscription else {
      log(.warn, "c47d3e0b")
      return .fallback
    }
    return subscription
  }

  @discardableResult
  static func set(
    status: Subscription.Status,
    expiringAt: Date,
    legacyMigrationNag: Bool = false,
  ) throws -> Subscription {
    dep(\.db).tryWrite { db in
      try Subscription
        .find(Subscription.ID(1))
        .update {
          $0.status = status
          $0.expiresAt = expiringAt
          $0.legacyMigrationNag = legacyMigrationNag
        }
        .returning { $0.self }
        .fetchOne(db)
    } ?? .fallback
  }
}
