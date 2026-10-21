import DuetSQL
import XCTest
import XExpect

@testable import Api

final class AccountAnnouncementResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsNilWhenThereAreNoActiveAnnouncements() async throws {
    let parent = try await self.parent()
    try await self.db.create(DashAnnouncement(
      parentId: parent.id,
      html: "expired",
      deletedAt: Date().addingTimeInterval(-60),
    ))
    let otherParent = try await self.parent()
    try await self.db.create(DashAnnouncement(parentId: otherParent.id, html: "not yours"))

    let output = try await GetAccountAnnouncement.resolve(in: self.accountContext(parent))

    expect(output.announcement).toBeNil()
  }

  func testReturnsOldestActiveAnnouncementWithContentAndAction() async throws {
    let parent = try await self.parent()
    var oldest = try await self.db.create(DashAnnouncement(
      parentId: parent.id,
      kind: .warning,
      icon: "fa-solid fa-triangle-exclamation",
      html: "<b>Action needed:</b> Disable Screen Time web filtering.",
      action: .init(
        label: "Learn more",
        url: "https://gertrude.app/help/mac/screen-time-filter-conflict",
      ),
    ))
    try await oldest.modifyCreatedAt(.exact(Date().addingTimeInterval(-120)))
    try await self.db.create(DashAnnouncement(parentId: parent.id, html: "newer news"))

    let output = try await GetAccountAnnouncement.resolve(in: self.accountContext(parent))
    let announcement = try XCTUnwrap(output.announcement)

    expect(announcement.id).toEqual(oldest.id)
    expect(announcement.kind).toEqual(.warning)
    expect(announcement.html).toEqual(oldest.html)
    expect(announcement.action).toEqual(oldest.action)
  }

  func testDismissalAdvancesToNextAnnouncement() async throws {
    let parent = try await self.parent()
    var first = try await self.db.create(DashAnnouncement(parentId: parent.id, html: "first"))
    try await first.modifyCreatedAt(.exact(Date().addingTimeInterval(-120)))
    let next = try await self.db.create(DashAnnouncement(parentId: parent.id, html: "next"))

    _ = try await DismissAccountAnnouncement.resolve(
      with: .init(id: first.id),
      in: self.accountContext(parent),
    )

    let output = try await GetAccountAnnouncement.resolve(in: self.accountContext(parent))
    expect(output.announcement?.id).toEqual(next.id)
  }
}
