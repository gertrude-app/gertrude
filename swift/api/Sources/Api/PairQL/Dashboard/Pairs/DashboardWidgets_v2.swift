import DuetSQL
import Foundation
import Gertie
import PairQL
import XAws

struct DashboardWidgets_v2: Pair {
  static let auth: ClientAuth = .parent

  enum DevicePlatform: String, PairNestable {
    case mac
    case ios
  }

  enum IOSDeviceStatus: String, PairNestable {
    case setupComplete
    case pendingSetup
  }

  struct DeviceInfo: PairNestable {
    var platform: DevicePlatform
    var deviceName: String
    var macStatus: ChildComputerStatus?
    var iosStatus: IOSDeviceStatus?
  }

  struct Child: PairNestable {
    var id: Api.Child.Id
    var name: String
    var devices: [DeviceInfo]
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

extension DashboardWidgets_v2: NoInputResolver {
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

    // step 1: fetch computerUsers and iosDevices concurrently (both depend only on children)
    async let computerUsersAsync = ComputerUser.query()
      .where(.childId |=| children.map(\.id))
      .all(in: context.db)
    async let iosDevicesAsync = IOSDevice.query()
      .where(.childId |=| children.map(\.id))
      .all(in: context.db)

    let computerUsers = try await computerUsersAsync
    let iosDevices = try await iosDevicesAsync

    let computerToChildMap: [ComputerUser.Id: Api.Child] = computerUsers
      .reduce(into: [:]) { map, device in
        map[device.id] = children.first(where: { $0.id == device.childId })
      }

    // step 2: launch all remaining queries concurrently
    async let computersAsync = Computer.query()
      .where(.id |=| computerUsers.map(\.computerId))
      .all(in: context.db)
    async let supervisionsAsync = BlockerApp.Supervision.query()
      .where(.deviceId |=| iosDevices.map(\.id))
      .all(in: context.db)
    async let blockerConnectedDeviceIdsAsync = BlockerApp.Token.connectedDeviceIds(
      among: iosDevices.map(\.id),
      in: context.db,
    )
    async let amConnectedDeviceIdsAsync = PodcastApp.Token.connectedDeviceIds(
      among: iosDevices.map(\.id),
      in: context.db,
    )
    async let unlockRequests = Api.UnlockRequest.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.status == .enum(RequestStatus.pending))
      .all(in: context.db)
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

    let computerMap: [Computer.Id: Computer] = try await computersAsync
      .reduce(into: [:]) { map, computer in map[computer.id] = computer }
    let supervisionMap: [IOSDevice.Id: BlockerApp.Supervision] = try await supervisionsAsync
      .reduce(into: [:]) { map, s in map[s.deviceId] = s }
    let connectedDeviceIds = try await blockerConnectedDeviceIdsAsync
      .union(amConnectedDeviceIdsAsync)

    return try await .init(
      children: children.concurrentMap { child in
        let macDevices: [DeviceInfo] = try await computerUsers
          .filter { $0.childId == child.id }
          .concurrentMap { computerUser in
            let computer = computerMap[computerUser.computerId]
            let deviceName = computer?.customName
              ?? computer?.model.shortDescription
              ?? "Mac"
            return await DeviceInfo(
              platform: .mac,
              deviceName: deviceName,
              macStatus: computerUser.status(),
              iosStatus: nil,
            )
          }

        let childIOSDevices: [DeviceInfo] = iosDevices
          .filter { $0.childId == child.id }
          .map { device in
            let supervision = supervisionMap[device.id]
            let isConnected = connectedDeviceIds.contains(device.id)
            let status: IOSDeviceStatus =
              supervision?.profileInstalled == true || isConnected
                ? .setupComplete
                : .pendingSetup
            return DeviceInfo(
              platform: .ios,
              deviceName: device.modelName,
              macStatus: nil,
              iosStatus: status,
            )
          }

        return Child(
          id: child.id,
          name: child.name,
          devices: macDevices + childIOSDevices,
        )
      },
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
        aws: with(dependency: \.aws),
        bucketUrl: with(dependency: \.env.s3.bucketUrl),
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
) -> [DashboardWidgets_v2.UnlockRequest] {
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
  aws: AWS.Client,
  bucketUrl: String,
) -> [DashboardWidgets_v2.RecentScreenshot] {
  children.compactMap { user in
    screenshots
      .first { map[$0.computerUserId]?.id == user.id }
      .map { screenshot in
        .init(
          id: screenshot.id,
          childName: user.name,
          url: signedScreenshotUrl(screenshot.url, bucketUrl: bucketUrl, aws: aws),
          createdAt: screenshot.createdAt,
        )
      }
  }
}

private func childActivitySummaries(
  children: [Child],
  map: [ComputerUser.Id: Child],
  keystrokes: [KeystrokeLine],
  screenshots: [Screenshot],
) -> [DashboardWidgets_v2.ChildActivitySummary] {
  children.map { user in
    let userScreenshots = screenshots.filter { map[$0.computerUserId]?.id == user.id }
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
      d.\(IOSDevice.columnName(.modelIdentifier)) AS model_identifier,
      d.\(IOSDevice.columnName(.claimCode)) AS claim_code
    FROM \(table: IOSDevice.self) d
    JOIN \(table: BlockerApp.Supervision.self) s
      ON s.\(BlockerApp.Supervision.columnName(.deviceId)) = d.id
    JOIN \(table: Child.self) c
      ON c.id = d.\(IOSDevice.columnName(.childId))
    WHERE c.\(Child.columnName(.parentId)) =\(" ")
    """)
    stmt.components.append(.binding(bindings[0]))
    stmt.components.append(.sql("""
      AND d.\(IOSDevice.columnName(.claimedAt)) IS NOT NULL
      AND d.\(IOSDevice.columnName(.claimCode)) IS NOT NULL
      AND s.\(BlockerApp.Supervision.columnName(.supervisedAt)) IS NULL
    """))
    return stmt
  }

  var childName: String
  var modelIdentifier: String
  var claimCode: Int
}
