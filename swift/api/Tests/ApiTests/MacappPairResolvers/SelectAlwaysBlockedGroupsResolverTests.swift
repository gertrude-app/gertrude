import Dependencies
import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class SelectAlwaysBlockedGroupsResolverTests: ApiTestCase, @unchecked Sendable {
  func testSuccessfullyAttachesGroups() async throws {
    let child = try await self.child().withDevice()

    let group1 = try await self.db.create(AlwaysBlockedGroup(
      name: "Adult content",
      description: "block adult content",
      longDescription: "block adult content of all kinds",
    ))
    let group2 = try await self.db.create(AlwaysBlockedGroup(
      name: "Spotlight search",
      description: "block spotlight search",
      longDescription: "block spotlight search results",
    ))

    let input: [UUID] = [group1.id.rawValue, group2.id.rawValue]
    let output = try await SelectAlwaysBlockedGroups.resolve(with: input, in: context(child))

    expect(output).toEqual(.success)

    let attached = try await ChildAlwaysBlockedGroup.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(attached).toHaveCount(2)
    let groupIds = Set(attached.map(\.groupId))
    expect(groupIds == Set([group1.id, group2.id])).toEqual(true)

    expect(self.sent.websocketMessages).toHaveCount(1)
    expect(self.sent.websocketMessages[0].message).toEqual(.userUpdated)
    expect(self.sent.websocketMessages[0].matcher).toEqual(.user(child.model.id))

    let events = try await InterestingEvent.query()
      .where(.eventId == "a582a19f")
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)

    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("selected 2 always-blocked group(s) during onboarding")
    expect(detail).toContain(group1.id.lowercased)
    expect(detail).toContain(group2.id.lowercased)
  }

  func testReplacesPriorSelection() async throws {
    let child = try await self.child().withDevice()

    let group1 = try await self.db.create(AlwaysBlockedGroup(
      name: "Adult content",
      description: "x",
      longDescription: "x",
    ))
    let group2 = try await self.db.create(AlwaysBlockedGroup(
      name: "Spotlight search",
      description: "x",
      longDescription: "x",
    ))
    let group3 = try await self.db.create(AlwaysBlockedGroup(
      name: "Messages GIF Search",
      description: "x",
      longDescription: "x",
    ))

    try await self.db.create(ChildAlwaysBlockedGroup(
      childId: child.model.id,
      groupId: group1.id,
    ))
    try await self.db.create(ChildAlwaysBlockedGroup(
      childId: child.model.id,
      groupId: group2.id,
    ))

    let input: [UUID] = [group3.id.rawValue]
    let output = try await SelectAlwaysBlockedGroups.resolve(with: input, in: context(child))
    expect(output).toEqual(.success)

    let attached = try await ChildAlwaysBlockedGroup.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(attached).toHaveCount(1)
    expect(attached.first?.groupId).toEqual(group3.id)
  }

  func testEmptyInputClearsAllPriorSelection() async throws {
    let child = try await self.child().withDevice()

    let group = try await self.db.create(AlwaysBlockedGroup(
      name: "Adult content",
      description: "x",
      longDescription: "x",
    ))
    try await self.db.create(ChildAlwaysBlockedGroup(
      childId: child.model.id,
      groupId: group.id,
    ))

    let output = try await SelectAlwaysBlockedGroups.resolve(with: [], in: context(child))
    expect(output).toEqual(.success)

    let attached = try await ChildAlwaysBlockedGroup.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(attached).toHaveCount(0)
    expect(self.sent.websocketMessages).toHaveCount(1)
  }

  func testRejectedWhenTokenTooOld() async throws {
    let child = try await self.child().withDevice()
    let group = try await self.db.create(AlwaysBlockedGroup(
      name: "Adult content",
      description: "x",
      longDescription: "x",
    ))

    let tooOld = child.token.createdAt.addingTimeInterval(91 * 60)
    do {
      try await withDependencies {
        $0.date = .constant(tooOld)
      } operation: {
        _ = try await SelectAlwaysBlockedGroups.resolve(
          with: [group.id.rawValue],
          in: self.context(child),
        )
      }
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }

    let attached = try await ChildAlwaysBlockedGroup.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(attached).toHaveCount(0)
    expect(self.sent.websocketMessages).toHaveCount(0)

    let events = try await InterestingEvent.query()
      .where(.eventId == "0e5d0d99")
      .all(in: self.db)

    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("suspicious SelectAlwaysBlockedGroups")
  }
}
