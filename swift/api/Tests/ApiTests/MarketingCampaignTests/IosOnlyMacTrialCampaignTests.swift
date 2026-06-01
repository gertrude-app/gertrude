import DuetSQL
import XCore
import XCTest
import XExpect

@testable import Api

final class IosOnlyMacTrialCampaignTests: ApiTestCase, @unchecked Sendable {
  func testAudienceIncludesVerifiedIosOnlyParentsWithOldConnectedCheckin() async throws {
    let now = Date()
    let eligible = try await self.verifiedIOSChild(tokenCreatedAt: now - .days(8))
    let tooRecent = try await self.verifiedIOSChild(tokenCreatedAt: now - .days(6))
    let noCheckin = try await self.verifiedIOSChild(
      tokenCreatedAt: now - .days(8),
      createCheckin: false,
    )
    let unverified = try await self.childWithIOSDevice()
    try await self.setTokenCreatedAt(unverified.token.id, to: now - .days(8))
    _ = try await self.createCheckin(for: unverified.device, at: now - .days(8))

    let audience = try await IosOnlyMacTrialCampaign().audience(in: self.db)
    let audienceParentIds = Set(audience.map(\.parentId))

    expect(audienceParentIds.contains(eligible.parent.model.id)).toEqual(true)
    expect(audienceParentIds.contains(tooRecent.parent.model.id)).toEqual(false)
    expect(audienceParentIds.contains(noCheckin.parent.model.id)).toEqual(false)
    expect(audienceParentIds.contains(unverified.parent.model.id)).toEqual(false)
  }

  func testAudienceExcludesParentsWithMacsTrialsOrFullSubscriptions() async throws {
    let now = Date()
    let eligible = try await self.verifiedIOSChild(tokenCreatedAt: now - .days(8))
    let withMac = try await self.verifiedIOSChild(tokenCreatedAt: now - .days(8))
    let withFullTrial = try await self.verifiedIOSChild(tokenCreatedAt: now - .days(8))
    let withFullSubscription = try await self.verifiedIOSChild(tokenCreatedAt: now - .days(8))

    _ = try await self.db.create(Computer.random {
      $0.parentId = withMac.parent.model.id
    })
    _ = try await self.db.create(BillingIdentity(
      parentId: withFullTrial.parent.model.id,
      fullTrialStartedAt: now - .days(1),
    ))
    _ = try await self.db.create(BillingIdentity(parentId: withFullSubscription.parent.model.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: withFullSubscription.parent.model.id,
      tier: .full,
      stripeId: "sub_ios_mac_intro_test",
      stripeStatus: .active,
      currentPeriodEnd: now + .days(30),
    ))

    let audience = try await IosOnlyMacTrialCampaign().audience(in: self.db)
    let audienceParentIds = Set(audience.map(\.parentId))

    expect(audienceParentIds.contains(eligible.parent.model.id)).toEqual(true)
    expect(audienceParentIds.contains(withMac.parent.model.id)).toEqual(false)
    expect(audienceParentIds.contains(withFullTrial.parent.model.id)).toEqual(false)
    expect(audienceParentIds.contains(withFullSubscription.parent.model.id)).toEqual(false)
  }

  func testAudienceTemplateModelUsesDeviceFragment() async throws {
    let now = Date()
    let child = try await self.verifiedIOSChild(
      tokenCreatedAt: now - .days(8),
      childName: "Sarah",
      modelIdentifier: "iPhone15,2",
    )

    let audience = try await IosOnlyMacTrialCampaign().audience(in: self.db)
    let recipient = try XCTUnwrap(audience.first { $0.parentId == child.parent.model.id })

    expect(recipient.templateModel).toEqual(["deviceFragment": "Sarah's iPhone"])
  }

  private func verifiedIOSChild(
    tokenCreatedAt: Date,
    childName: String = "Franny",
    modelIdentifier: String = "iPhone15,2",
    createCheckin: Bool = true,
  ) async throws -> ChildWithIOSDeviceEntities {
    var child = try await self.childWithIOSDevice()
    var parent = child.parent.model
    parent.emailVerifiedAt = Date()
    try await self.db.update(parent)
    child.parent = .init(model: parent, token: child.parent.token)

    var model = child.model
    model.name = childName
    try await self.db.update(model)
    child.model = model

    var device = child.device
    device.modelIdentifier = modelIdentifier
    try await self.db.update(device)
    child.device = device

    try await self.setTokenCreatedAt(child.token.id, to: tokenCreatedAt)
    if createCheckin {
      _ = try await self.createCheckin(for: device, at: tokenCreatedAt)
    }
    return child
  }

  private func createCheckin(for device: IOSDevice, at date: Date) async throws -> IOSEvent {
    var event = try await self.db.create(IOSEvent(
      eventId: "b977cfdc",
      kind: .checkin,
      deviceId: device.id,
      modelIdentifier: device.modelIdentifier,
      iosVersion: device.iosVersion,
    ))
    event.createdAt = date
    try await self.db.update(event)
    return event
  }

  private func setTokenCreatedAt(_ tokenId: BlockerApp.Token.Id, to date: Date) async throws {
    var stmt = SQL.Statement("""
    UPDATE \(table: BlockerApp.Token.self) SET \(BlockerApp.Token.columnName(.createdAt)) =
    """)
    stmt.components.append(.binding(.date(date)))
    stmt.components.append(.sql(" WHERE \(BlockerApp.Token.columnName(.id)) = "))
    stmt.components.append(.binding(.uuid(tokenId)))
    try await self.db.execute(statement: stmt)
  }
}
