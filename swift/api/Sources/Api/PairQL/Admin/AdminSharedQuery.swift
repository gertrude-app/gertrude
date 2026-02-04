import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL
import TaggedMoney

enum ParentAnalyticsStatus: String, Codable {
  case noAction = "no_action"
  case onboarded
  case active
}

struct ParentData: Sendable {
  var id: Parent.Id
  var email: EmailAddress
  var numComputerUsers: Int
  var numChildren: Int
  var numNonEmptyKeychains: Int
  var numNotifications: Int
  var childActivityCount: Int
  // TODO: this name is weird, rename to monthlyPaidPriceCents?
  // @see https://github.com/gertrude-app/gertrude/issues/478
  var paidPrice: Cents<Int>?
  var hasGclid: Bool
  var createdAt: Date

  init(model: Parent, subscription: Subscription?) {
    self.id = model.id
    self.email = model.email
    self.numComputerUsers = 0
    self.numChildren = 0
    self.numNonEmptyKeychains = 0
    self.numNotifications = 0
    self.childActivityCount = 0
    self.paidPrice = Plan(subscription: subscription).monthlyPrice
    self.hasGclid = model.gclid != nil
    self.createdAt = model.createdAt
  }
}

struct Overview {
  var annualRevenue: Dollars<Int>
  var payingParents: Int
  var activeParents: Int
  var childrenOfActiveParents: Int
  var allTimeSignups: Int
  var allTimeChildren: Int
  var allTimeAppInstallations: Int
}

struct AnalyticsData: Sendable {
  var parents: [Parent.Id: ParentData]
  var overview: Overview
}

@globalActor actor AnalyticsQuery {
  static let shared = AnalyticsQuery()
  private var _data: AnalyticsData?

  @Dependency(\.db) private var db
  @Dependency(\.logger) private var logger

  init() {}

  func data() async throws -> AnalyticsData {
    if let data = _data { return data }
    let data = try await self.queryFreshData()
    self._data = data
    return data
  }

  func queryFreshData() async throws -> AnalyticsData {
    self.logger.notice("Querying analytics data")
    let parentModels = try await Parent.query()
      .where(.not(.like(.email, "%.smoke-test-%")))
      .where(.not(.like(.email, "e2e-user-%")))
      .where(.not(.isNull(.emailVerifiedAt)))
      .all(in: self.db)

    let allSubscriptions = try await Subscription.query().all(in: self.db)
    let subscriptionMap = Dictionary(uniqueKeysWithValues: allSubscriptions
      .map { ($0.parentId, $0) })

    let nonEmptyKeyChains = try await self.db.customQuery(NonEmptyKeychains.self)
    let keychainMap: [Parent.Id: [Int]] = nonEmptyKeyChains.reduce(into: [:]) { map, row in
      map[row.parentId, default: []].append(row.keyCount)
    }

    let notificationsCount = try await self.db.customQuery(NotificationsCount.self)
    let notificationsMap: [Parent.Id: Int] = notificationsCount.reduce(into: [:]) { map, row in
      map[row.parentId] = row.notificationsCount
    }

    let childCount = try await self.db.customQuery(ChildCount.self)
    let childMap: [Parent.Id: Int] = childCount.reduce(into: [:]) { map, child in
      map[child.parentId] = child.childCount
    }

    let computerUserCount = try await self.db.customQuery(ComputerUserCount.self)
    let computerUserMap: [Parent.Id: Int] = computerUserCount.reduce(into: [:]) { map, row in
      map[row.parentId] = row.computerUserCount
    }

    let activityCounts = try await self.db.customQuery(ActivityCounts.self)
    let activityMap: [Parent.Id: Int] = activityCounts.reduce(into: [:]) { map, row in
      map[row.parentId] = row.screenshotCount + row.keystrokeLineCount
    }

    var data = try await AnalyticsData(
      parents: [:],
      overview: .init(
        annualRevenue: 0,
        payingParents: 0,
        activeParents: 0,
        childrenOfActiveParents: 0,
        allTimeSignups: parentModels.count,
        allTimeChildren: Child.query().count(in: self.db),
        allTimeAppInstallations: ComputerUser.query().count(in: self.db),
      ),
    )
    var totalAnnualCents = Cents(0)
    var parents = parentModels.reduce(into: [Parent.Id: ParentData]()) { map, model in
      var parent = ParentData(model: model, subscription: subscriptionMap[model.id])
      parent.numNonEmptyKeychains = keychainMap[model.id]?.count ?? 0
      parent.numChildren = childMap[model.id] ?? 0
      parent.numNotifications = notificationsMap[model.id] ?? 0
      parent.numComputerUsers = computerUserMap[model.id] ?? 0
      parent.childActivityCount = activityMap[model.id] ?? 0
      if parent.isActive {
        data.overview.activeParents += 1
        data.overview.childrenOfActiveParents += parent.numChildren
      }
      map[parent.id] = parent
      if let paidPrice = parent.paidPrice {
        totalAnnualCents += paidPrice * 12
        data.overview.payingParents += 1
      }
    }
    data.overview.annualRevenue = Dollars(totalAnnualCents.rawValue / 100)

    let children = try await Child.query().all(in: self.db)
    for child in children {
      guard var parent = parents[child.parentId] else { continue }
      parent.numChildren += 1
      parents[child.parentId] = parent
    }

    data.parents = parents
    self._data = data
    return data
  }
}

extension ParentData {
  var isActive: Bool {
    self.numComputerUsers > 0
      && self.numNotifications > 0
      && (self.numNonEmptyKeychains > 0 || self.childActivityCount > 0)
  }

  var status: ParentAnalyticsStatus {
    if self.isActive {
      .active
    } else if self.numComputerUsers > 0 {
      .onboarded
    } else {
      .noAction
    }
  }
}

// custom queries

struct NonEmptyKeychains: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT kc.\(Keychain.columnName(.parentId)), COUNT(k.id) AS key_count
    FROM \(table: Keychain.self) kc
    LEFT JOIN \(table: Key.self) k ON k.\(Key.columnName(.keychainId)) = kc.id
    WHERE kc.\(Keychain.columnName(.isPublic)) = false
    GROUP BY kc.id, kc.\(Keychain.columnName(.parentId))
    HAVING COUNT(k.id) > 0;
    """)
  }

  var parentId: Parent.Id
  var keyCount: Int
}

struct ChildCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT p.id AS parent_id, COUNT(c.id) AS child_count
    FROM \(table: Parent.self) p
    LEFT JOIN \(table: Child.self) c ON c.\(Child.columnName(.parentId)) = p.id
    GROUP BY p.id;
    """)
  }

  var parentId: Parent.Id
  var childCount: Int
}

struct NotificationsCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT p.id AS parent_id, COUNT(c.id) AS notifications_count
    FROM \(table: Parent.self) p
    LEFT JOIN \(table: Parent.Notification.self) c
      ON c.\(Parent.Notification.columnName(.parentId)) = p.id
    GROUP BY p.id;
    """)
  }

  var parentId: Parent.Id
  var notificationsCount: Int
}

struct ComputerUserCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT p.id AS parent_id, COUNT(DISTINCT cu.id) AS computer_user_count
    FROM \(table: Parent.self) p
    JOIN \(table: Computer.self) c
      ON c.\(Computer.columnName(.parentId)) = p.id
    JOIN \(table: ComputerUser.self) cu
      ON cu.\(ComputerUser.columnName(.computerId)) = c.id
    GROUP BY p.id;
    """)
  }

  var parentId: Parent.Id
  var computerUserCount: Int
}

struct ActivityCounts: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    WITH ss_counts AS (
      SELECT cu.\(ComputerUser.columnName(.computerId)), COUNT(*) AS screenshot_count
      FROM \(table: Screenshot.self) ss
      JOIN \(table: ComputerUser.self) cu
        ON ss.\(Screenshot.columnName(.computerUserId)) = cu.id
      GROUP BY cu.\(ComputerUser.columnName(.computerId))
    ),
    kl_counts AS (
      SELECT cu.\(ComputerUser.columnName(.computerId)), COUNT(*) AS keystroke_line_count
      FROM \(table: KeystrokeLine.self) kl
      JOIN \(table: ComputerUser.self) cu
        ON kl.\(KeystrokeLine.columnName(.computerUserId)) = cu.id
      GROUP BY cu.\(ComputerUser.columnName(.computerId))
    )
    SELECT p.id AS parent_id,
           COALESCE(SUM(ss.screenshot_count), 0)::int AS screenshot_count,
           COALESCE(SUM(kl.keystroke_line_count), 0)::int AS keystroke_line_count
    FROM \(table: Parent.self) p
    JOIN \(table: Computer.self) c ON c.\(Computer.columnName(.parentId)) = p.id
    LEFT JOIN ss_counts ss
      ON ss.\(ComputerUser.columnName(.computerId)) = c.id
    LEFT JOIN kl_counts kl
      ON kl.\(ComputerUser.columnName(.computerId)) = c.id
    GROUP BY p.id;
    """)
  }

  var parentId: Parent.Id
  var screenshotCount: Int
  var keystrokeLineCount: Int
}
