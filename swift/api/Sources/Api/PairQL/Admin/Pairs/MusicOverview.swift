import Dependencies
import DuetSQL
import PairQL

struct MusicOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var totalInstalls: Int
    var connectedMusicUsers: Int
    var paidMusicFamilies: Int
    var approvedAlbums: Int
    var iPhoneInstalls: Int
    var iPadInstalls: Int
    var statusBreakdown: StatusBreakdown
    var recentInstalls: [RecentInstall]
  }

  struct StatusBreakdown: PairNestable {
    var paid: Int
    var complimentary: Int
    var connected: Int
    var unclaimed: Int
  }

  struct RecentInstall: PairNestable {
    var date: Date
    var deviceType: String
    var status: String
  }
}

extension MusicOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now
    let rows = try await context.db.customQuery(MusicOverviewRowsQuery.self)
    var breakdown = StatusBreakdown(paid: 0, complimentary: 0, connected: 0, unclaimed: 0)
    var recentInstalls: [RecentInstall] = []
    var iPhoneInstalls = 0
    var iPadInstalls = 0
    var connectedMusicUsers = 0
    var paidMusicParentIds = Set<Parent.Id>()
    let accountsByDeviceId = try await Self.accountsByDeviceId(
      for: rows.map { IOSDevice.Id($0.deviceId) },
      at: now,
      in: context.db,
    )

    for row in rows {
      if row.connected {
        connectedMusicUsers += 1
      }
      if row.modelIdentifier.contains("iPhone") {
        iPhoneInstalls += 1
      } else if row.modelIdentifier.contains("iPad") {
        iPadInstalls += 1
      }
      let account = accountsByDeviceId[IOSDevice.Id(row.deviceId)]
      let status = MusicInstallsList.status(
        connected: row.connected,
        snapshot: account?.snapshot,
      )
      switch status {
      case "paid": breakdown.paid += 1
      case "complimentary": breakdown.complimentary += 1
      case "connected": breakdown.connected += 1
      case "unclaimed": breakdown.unclaimed += 1
      default: break
      }
      if status == "paid", let parentId = account?.parentId {
        paidMusicParentIds.insert(parentId)
      }
      recentInstalls.append(RecentInstall(
        date: row.date,
        deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
        status: status,
      ))
    }

    return try await .init(
      totalInstalls: rows.count,
      connectedMusicUsers: connectedMusicUsers,
      paidMusicFamilies: paidMusicParentIds.count,
      approvedAlbums: context.db.count(MusicApprovedAlbumCount.self),
      iPhoneInstalls: iPhoneInstalls,
      iPadInstalls: iPadInstalls,
      statusBreakdown: breakdown,
      recentInstalls: recentInstalls,
    )
  }

  private struct MusicAccount {
    var parentId: Parent.Id
    var snapshot: BillingAccountSnapshot
  }

  private static func accountsByDeviceId(
    for deviceIds: [IOSDevice.Id],
    at now: Date,
    in db: any DuetSQL.Client,
  ) async throws -> [IOSDevice.Id: MusicAccount] {
    guard !deviceIds.isEmpty else {
      return [:]
    }

    let devices = try await IOSDevice.query()
      .where(.id |=| deviceIds)
      .all(in: db)
    let childIds = devices.compactMap(\.childId)
    guard !childIds.isEmpty else {
      return [:]
    }

    let children = try await Child.query()
      .where(.id |=| childIds)
      .all(in: db)
    let parentIds = Array(Set(children.map(\.parentId)))

    async let identities = BillingIdentity.query()
      .where(.parentId |=| parentIds)
      .all(in: db)
    async let subscriptions = StripeSubscription.query()
      .where(.parentId |=| parentIds)
      .all(in: db)

    var identitiesByParentId: [Parent.Id: BillingIdentity] = [:]
    for identity in try await identities {
      identitiesByParentId[identity.parentId] = identity
    }

    var subscriptionsByParentId: [Parent.Id: StripeSubscription] = [:]
    for subscription in try await subscriptions {
      subscriptionsByParentId[subscription.parentId] = subscription
    }

    var childrenById: [Child.Id: Child] = [:]
    for child in children {
      childrenById[child.id] = child
    }

    var accountsByDeviceId: [IOSDevice.Id: MusicAccount] = [:]
    for device in devices {
      guard let childId = device.childId,
            let child = childrenById[childId] else {
        continue
      }
      accountsByDeviceId[device.id] = MusicAccount(
        parentId: child.parentId,
        snapshot: BillingAccountSnapshot(
          billingIdentity: identitiesByParentId[child.parentId],
          stripeSubscription: subscriptionsByParentId[child.parentId],
          date: now,
        ),
      )
    }
    return accountsByDeviceId
  }
}

private struct MusicOverviewRowsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let installDevice = MusicApp.Install.columnName(.deviceId)
    let installCreated = MusicApp.Install.columnName(.createdAt)
    let installId = MusicApp.Install.columnName(.id)
    let deviceId = IOSDevice.columnName(.id)
    let deviceModel = IOSDevice.columnName(.modelIdentifier)
    let tokenInstall = MusicApp.Token.columnName(.installId)
    return SQL.Statement("""
    SELECT
      i.\(installDevice) AS device_id,
      i.\(installCreated) AS date,
      d.\(deviceModel) AS model_identifier,
      CASE WHEN t.\(tokenInstall) IS NOT NULL THEN true ELSE false END AS connected
    FROM \(table: MusicApp.Install.self) i
    JOIN \(table: IOSDevice.self) d ON d.\(deviceId) = i.\(installDevice)
    LEFT JOIN \(table: MusicApp.Token.self) t ON t.\(tokenInstall) = i.\(installId)
    ORDER BY i.\(installCreated) DESC
    """)
  }

  var deviceId: UUID
  var date: Date
  var modelIdentifier: String
  var connected: Bool
}

private struct MusicApprovedAlbumCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(*) AS count
    FROM \(table: Music.ApprovedAlbum.self)
    """)
  }

  var count: Int
}
