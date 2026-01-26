import DuetSQL
import Foundation
import Gertie
import PairQL

struct DashboardWidgets: Pair {
  static let auth: ClientAuth = .parent

  struct Child: PairNestable {
    var id: Api.Child.Id
    var name: String
    var status: ChildComputerStatus
    var numDevices: Int
  }

  struct ChildActivitySummary: PairNestable {
    var id: Api.Child.Id
    var name: String
    var numUnreviewed: Int
    var numReviewed: Int
  }

  struct UnlockRequest: PairNestable {
    var id: Api.UnlockRequest.Id
    var childId: Api.Child.Id
    var childName: String
    var target: String
    var comment: String?
    var createdAt: Date
  }

  struct RecentScreenshot: PairNestable {
    var id: Screenshot.Id
    var childName: String
    var url: String
    var createdAt: Date
  }

  struct Announcement: PairNestable {
    var id: DashAnnouncement.Id
    var kind: DashAnnouncement.Kind
    var icon: String?
    var html: String
    var learnMoreUrl: String?
  }

  struct PendingIOSDevice: PairNestable {
    var childName: String
    var modelName: String
    var claimCode: Int
  }

  struct Output: PairOutput {
    var children: [Child]
    var childActivitySummaries: [ChildActivitySummary]
    var unlockRequests: [UnlockRequest]
    var recentScreenshots: [RecentScreenshot]
    var numParentNotifications: Int
    var announcement: Announcement?
    var pendingIOSDevices: [PendingIOSDevice]
  }
}

// resolver

extension DashboardWidgets: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let children = try await Api.Child.query()
      .where(.parentId == context.parent.id)
      .all(in: context.db)

    guard !children.isEmpty else {
      return Output(
        children: [],
        childActivitySummaries: [],
        unlockRequests: [],
        recentScreenshots: [],
        numParentNotifications: 0,
        announcement: nil,
        pendingIOSDevices: [],
      )
    }

    let computerUsers = try await ComputerUser.query()
      .where(.childId |=| children.map(\.id))
      .all(in: context.db)

    let unlockRequests = try await Api.UnlockRequest.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.status == .enum(RequestStatus.pending))
      .all(in: context.db)

    let computerToChildMap: [ComputerUser.Id: Api.Child] = computerUsers
      .reduce(into: [:]) { map, device in
        map[device.id] = children.first(where: { $0.id == device.childId })
      }

    async let keystrokes = KeystrokeLine.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    async let screenshots = Screenshot.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    async let notifications = context.parent.notifications(in: context.db)

    async let announcement = try? await DashAnnouncement.query()
      .where(.parentId == context.parent.id)
      .orderBy(.createdAt, .asc)
      .first(in: context.db)

    async let pendingDeviceRows = context.db.customQuery(
      PendingIOSDeviceRow.self,
      withBindings: [.uuid(context.parent.id)],
    )

    return try await .init(
      children: children.concurrentMap { user in try await .init(
        id: user.id,
        name: user.name,
        status: consolidatedChildComputerStatus(user.id, computerUsers),
        numDevices: computerUsers.count(where: { $0.childId == user.id }),
      ) },
      childActivitySummaries: childActivitySummaries(
        children: children,
        map: computerToChildMap,
        keystrokes: keystrokes,
        screenshots: screenshots,
      ),
      unlockRequests: mapUnlockRequests(
        unlockRequests: unlockRequests,
        map: computerToChildMap,
      ),
      recentScreenshots: recentScreenshots(
        children: children,
        map: computerToChildMap,
        screenshots: screenshots,
      ),
      numParentNotifications: notifications.count,
      announcement: announcement.map { .init(
        id: $0.id,
        kind: $0.kind,
        icon: $0.icon,
        html: $0.html,
        learnMoreUrl: $0.learnMoreUrl,
      ) },
      pendingIOSDevices: pendingDeviceRows.map { row in .init(
        childName: row.childName,
        modelName: ModelIdentifier.marketingName(for: row.modelIdentifier),
        claimCode: row.claimCode,
      ) },
    )
  }
}

// helpers

private func mapUnlockRequests(
  unlockRequests: [Api.UnlockRequest],
  map: [ComputerUser.Id: Child],
) -> [DashboardWidgets.UnlockRequest] {
  unlockRequests.map { unlockRequest in
    .init(
      id: unlockRequest.id,
      childId: map[unlockRequest.computerUserId]?.id ?? .init(),
      childName: map[unlockRequest.computerUserId]?.name ?? "",
      target: unlockRequest.target ?? "",
      comment: unlockRequest.requestComment,
      createdAt: unlockRequest.createdAt,
    )
  }
}

private func recentScreenshots(
  children: [Child],
  map: [ComputerUser.Id: Child],
  screenshots: [Screenshot],
) -> [DashboardWidgets.RecentScreenshot] {
  children.compactMap { user in
    screenshots
      .first { map[$0.computerUserId ?? .init()]?.id == user.id }
      .map { .init(id: $0.id, childName: user.name, url: $0.url, createdAt: $0.createdAt) }
  }
}

private func childActivitySummaries(
  children: [Child],
  map: [ComputerUser.Id: Child],
  keystrokes: [KeystrokeLine],
  screenshots: [Screenshot],
) -> [DashboardWidgets.ChildActivitySummary] {
  children.map { user in
    let userScreenshots = screenshots.filter { map[$0.computerUserId ?? .init()]?.id == user.id }
    let userKeystrokes = keystrokes.filter { map[$0.computerUserId]?.id == user.id }
    return .init(
      id: user.id,
      name: user.name,
      numUnreviewed: coalesce(
        userScreenshots.filter(\.notDeleted),
        userKeystrokes.filter(\.notDeleted),
      ).count,
      numReviewed: coalesce(
        userScreenshots.filter(\.isDeleted),
        userKeystrokes.filter(\.isDeleted),
      ).count,
    )
  }
}

struct PendingIOSDeviceRow: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT
      c.\(Child.columnName(.name)) AS child_name,
      d.\(IOSApp.Device.columnName(.modelIdentifier)) AS model_identifier,
      s.\(IOSApp.Supervision.columnName(.claimCode)) AS claim_code
    FROM \(table: IOSApp.Supervision.self) s
    JOIN \(table: IOSApp.Device.self) d
      ON d.id = s.\(IOSApp.Supervision.columnName(.deviceId))
    JOIN \(table: Child.self) c
      ON c.id = d.\(IOSApp.Device.columnName(.childId))
    WHERE c.\(Child.columnName(.parentId)) =\(" ")
    """)
    stmt.components.append(.binding(bindings[0]))
    stmt.components.append(.sql("""
      AND s.\(IOSApp.Supervision.columnName(.claimedAt)) IS NOT NULL
      AND s.\(IOSApp.Supervision.columnName(.supervisedAt)) IS NULL
    """))
    return stmt
  }

  var childName: String
  var modelIdentifier: String
  var claimCode: Int
}
