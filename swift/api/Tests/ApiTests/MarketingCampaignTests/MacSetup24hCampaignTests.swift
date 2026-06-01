import DuetSQL
import XCore
import XCTest
import XExpect

@testable import Api

final class MacSetup24hCampaignTests: ApiTestCase, @unchecked Sendable {
  func testAudienceIncludesDueActiveTrialParentsWithChildren() async throws {
    let now = Date()
    let eligible = try await self.child()
    let expiredTrial = try await self.child()
    let tooRecent = try await self.child()
    let childless = try await self.parent()

    _ = try await self.db.create(BillingIdentity(
      parentId: eligible.parent.model.id,
      fullTrialStartedAt: now - .hours(25),
    ))
    _ = try await self.db.create(BillingIdentity(
      parentId: expiredTrial.parent.model.id,
      fullTrialStartedAt: now - .days(22),
    ))
    _ = try await self.db.create(BillingIdentity(
      parentId: tooRecent.parent.model.id,
      fullTrialStartedAt: now - .hours(23),
    ))
    _ = try await self.db.create(BillingIdentity(
      parentId: childless.id,
      fullTrialStartedAt: now - .hours(25),
    ))
    try await self.setChildCreatedAt(eligible.model.id, to: now - .hours(30))
    try await self.setChildCreatedAt(expiredTrial.model.id, to: now - .days(23))
    try await self.setChildCreatedAt(tooRecent.model.id, to: now - .hours(30))

    let audience = try await MacSetup24hCampaign(dashboardUrl: "https://dash.test")
      .audience(in: self.db)
    let audienceParentIds = Set(audience.map(\.parentId))

    expect(audienceParentIds.contains(eligible.parent.model.id)).toEqual(true)
    expect(audienceParentIds.contains(expiredTrial.parent.model.id)).toEqual(false)
    expect(audienceParentIds.contains(tooRecent.parent.model.id)).toEqual(false)
    expect(audienceParentIds.contains(childless.id)).toEqual(false)
  }

  func testAudienceExcludesParentsWithConnectedMacs() async throws {
    let now = Date()
    let dueWithoutMac = try await self.child()
    let dueWithMac = try await self.childWithComputer()

    _ = try await self.db.create(BillingIdentity(
      parentId: dueWithoutMac.parent.model.id,
      fullTrialStartedAt: now - .hours(25),
    ))
    _ = try await self.db.create(BillingIdentity(
      parentId: dueWithMac.parent.model.id,
      fullTrialStartedAt: now - .hours(25),
    ))
    try await self.setChildCreatedAt(dueWithoutMac.model.id, to: now - .hours(30))
    try await self.setChildCreatedAt(dueWithMac.model.id, to: now - .hours(30))

    let audience = try await MacSetup24hCampaign(dashboardUrl: "https://dash.test")
      .audience(in: self.db)
    let audienceParentIds = Set(audience.map(\.parentId))

    expect(audienceParentIds.contains(dueWithoutMac.parent.model.id)).toEqual(true)
    expect(audienceParentIds.contains(dueWithMac.parent.model.id)).toEqual(false)
  }

  func testAudienceTemplateModelUsesChildNameAndMacUrlForOneChild() async throws {
    let now = Date()
    let child = try await self.child(with: \.name, of: "Sarah")
    _ = try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      fullTrialStartedAt: now - .hours(25),
    ))
    try await self.setChildCreatedAt(child.model.id, to: now - .hours(30))

    let audience = try await MacSetup24hCampaign(
      dashboardUrl: "https://dash.test/",
    ).audience(in: self.db)
    let recipient = try XCTUnwrap(audience.first { $0.parentId == child.parent.model.id })

    expect(recipient.templateModel).toEqual([
      "childName": "Sarah",
      "dashboardUrl": "https://dash.test",
      "primaryCtaUrl": "https://dash.test/children/\(child.model.id.lowercased)/mac",
    ])
  }

  func testAudienceTemplateModelUsesGenericCopyAndChildrenUrlForMultipleChildren() async throws {
    let now = Date()
    let parent = try await self.parent()
    let child1 = try await self.db.create(Child(parentId: parent.id, name: "Sarah"))
    let child2 = try await self.db.create(Child(parentId: parent.id, name: "Billy"))
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: now - .hours(25),
    ))
    try await self.setChildCreatedAt(child1.id, to: now - .hours(30))
    try await self.setChildCreatedAt(child2.id, to: now - .hours(29))

    let audience = try await MacSetup24hCampaign(
      dashboardUrl: "https://dash.test",
    ).audience(in: self.db)
    let recipient = try XCTUnwrap(audience.first { $0.parentId == parent.id })

    expect(recipient.templateModel).toEqual([
      "childName": "your child",
      "dashboardUrl": "https://dash.test",
      "primaryCtaUrl": "https://dash.test/children",
    ])
  }

  func testAudienceUsesFirstChildCreatedAtWhenChildWasCreatedAfterTrialStart() async throws {
    let now = Date()
    let due = try await self.child()
    let notDue = try await self.child()

    _ = try await self.db.create(BillingIdentity(
      parentId: due.parent.model.id,
      fullTrialStartedAt: now - .hours(40),
    ))
    _ = try await self.db.create(BillingIdentity(
      parentId: notDue.parent.model.id,
      fullTrialStartedAt: now - .hours(40),
    ))
    try await self.setChildCreatedAt(due.model.id, to: now - .hours(25))
    try await self.setChildCreatedAt(notDue.model.id, to: now - .hours(23))

    let audience = try await MacSetup24hCampaign(dashboardUrl: "https://dash.test")
      .audience(in: self.db)
    let audienceParentIds = Set(audience.map(\.parentId))

    expect(audienceParentIds.contains(due.parent.model.id)).toEqual(true)
    expect(audienceParentIds.contains(notDue.parent.model.id)).toEqual(false)
  }

  private func setChildCreatedAt(_ childId: Child.Id, to date: Date) async throws {
    var stmt = SQL.Statement("""
    UPDATE \(table: Child.self) SET \(Child.columnName(.createdAt)) =
    """)
    stmt.components.append(.binding(.date(date)))
    stmt.components.append(.sql(" WHERE \(Child.columnName(.id)) = "))
    stmt.components.append(.binding(.uuid(childId)))
    try await self.db.execute(statement: stmt)
  }
}
