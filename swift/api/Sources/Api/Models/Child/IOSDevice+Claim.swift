import Dependencies
import DuetSQL
import Foundation

extension IOSDevice {
  func ensureBlockerBlockGroups(in db: any DuetSQL.Client) async throws {
    let existing = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == self.id)
      .all(in: db)
    guard existing.isEmpty else { return }
    let groups = try await BlockerApp.BlockGroup.query()
      .where(.optIn == false)
      .all(in: db)
    try await db.create(groups.map {
      BlockerApp.DeviceBlockGroup(deviceId: self.id, blockGroupId: $0.id)
    })
  }

  mutating func bindChild(_ child: Child, in db: any DuetSQL.Client) async throws {
    self.childId = child.id
    try await self.stampLegacyAmIapIfQualifying(for: child, in: db)
    try await db.update(self)
  }

  private func stampLegacyAmIapIfQualifying(
    for child: Child,
    in db: any DuetSQL.Client,
  ) async throws {
    let earliest = try await db.customQuery(
      EarliestGrandfatherableLegacyIapForDevice.self,
      withBindings: [.uuid(self.id.rawValue)],
    )
    guard let paidAt = earliest.first?.createdAt else {
      return
    }
    let parent = try await child.parent(in: db)
    var identity = try await parent.ensureBillingIdentity(in: db)
    if let existing = identity.legacyAmIapPaidAt, existing <= paidAt {
      return
    }
    identity.legacyAmIapPaidAt = paidAt
    try await db.update(identity)
  }
}
