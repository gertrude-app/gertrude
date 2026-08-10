import DuetSQL
import XCTest
import XExpect

@testable import Api

final class DeleteAnnouncementResolverTests: ApiTestCase, @unchecked Sendable {
  func testDismissingExpiresAnnouncementButKeepsRowAsCampaignRecord() async throws {
    let parent = try await self.parent()
    let announcement = try await self.db.create(DashAnnouncement(
      parentId: parent.id,
      campaign: "test_campaign",
      html: "hello",
    ))

    try await DeleteEntity_v2.resolve(
      with: .init(id: announcement.id.rawValue, type: .announcement),
      in: parent.context,
    )

    let live = try await DashAnnouncement.query() // default filter excludes expired
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(live).toHaveCount(0)

    let all = try await DashAnnouncement.query()
      .withSoftDeleted()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(all).toHaveCount(1) // row survives — it's the record of what we announced
    expect(all[0].campaign).toEqual("test_campaign")
  }

  func testCampaignIsUniquePerParentButNilCampaignsAreUnconstrained() async throws {
    let parent = try await self.parent()
    try await self.db.create(DashAnnouncement(
      parentId: parent.id,
      campaign: "test_campaign",
      html: "first",
    ))

    await expectErrorFrom {
      try await self.db.create(DashAnnouncement(
        parentId: parent.id,
        campaign: "test_campaign",
        html: "duplicate",
      ))
    }

    // system warnings carry no campaign, so they can recur
    try await self.db.create(DashAnnouncement(parentId: parent.id, html: "warning one"))
    try await self.db.create(DashAnnouncement(parentId: parent.id, html: "warning two"))

    let all = try await DashAnnouncement.query()
      .withSoftDeleted()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(all).toHaveCount(3)
  }
}
