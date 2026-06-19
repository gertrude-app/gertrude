import Dependencies
import DuetSQL
import Foundation

struct ParentContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let parent: Parent
  let ipAddress: String?
  let telemetry: TelemetryBag

  @Dependency(\.db) var db
  @Dependency(\.env) var env

  func currentBillingAccount() async throws -> BillingAccountSnapshot {
    @Dependency(\.date.now) var now
    return try await self.parent.billingAccountSnapshot(in: self.db, at: now)
  }

  @discardableResult
  func verifiedChild(from id: Child.Id) async throws -> Child {
    try await Child.query()
      .where(.id == id)
      .where(.parentId == self.parent.id)
      .first(in: self.db)
  }

  func verifiedChildWithConnectedMusicApp(from id: Child.Id) async throws -> Child {
    let child = try await self.verifiedChild(from: id)
    let account = try await self.currentBillingAccount()
    try requireGertrudeMusicAccess(in: self, billing: account)

    let devices = try await child.iosDevices(in: self.db)
    let connectedDeviceIds = try await MusicApp.Token.connectedDeviceIds(
      among: devices.map(\.id),
      in: self.db,
    )
    guard !connectedDeviceIds.isEmpty else {
      throw self.error(
        "1fa9493f",
        .badRequest,
        user: "Connect Gertrude Music for this child before managing music.",
      )
    }
    return child
  }

  func children() async throws -> [Child] {
    try await Child.query()
      .where(.parentId == self.parent.id)
      .all(in: self.db)
  }

  func computerUsers() async throws -> [ComputerUser] {
    let children = try await self.children()
    return try await ComputerUser.query()
      .where(.childId |=| children.map(\.id))
      .all(in: self.db)
  }

  func persistTimeZone(_ timeZone: String) async {
    guard TimeZone(identifier: timeZone) != nil, self.parent.timeZone != timeZone else {
      return
    }
    var parent = self.parent
    parent.timeZone = timeZone
    _ = try? await self.db.update(parent)
  }
}
