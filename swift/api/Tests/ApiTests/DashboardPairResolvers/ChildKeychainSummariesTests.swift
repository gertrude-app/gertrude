import Dependencies
import Gertie
import XCTest
import XExpect

@testable import Api

final class ChildKeychainSummariesTests: ApiTestCase, @unchecked Sendable {
  func testReturnsAllKeychainsWithCorrectKeyCounts() async throws {
    let child = try await self.child()
    let parent = child.parent

    let kc1 = try await self.db.create(Keychain(
      parentId: parent.model.id,
      name: "kc1",
      description: "desc",
    ))
    let kc2 = try await self.db.create(Keychain(parentId: parent.model.id, name: "kc2"))
    let kc1Schedule = RuleSchedule(
      mode: .active,
      days: .all,
      window: .init(start: .init(hour: 8, minute: 0), end: .init(hour: 17, minute: 0)),
    )
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: kc1.id,
      schedule: kc1Schedule,
    ))
    try await self.db.create(ChildKeychain(childId: child.model.id, keychainId: kc2.id))

    try await self.db.create([
      Key(keychainId: kc1.id, key: .domain(domain: "a.com", scope: .webBrowsers)),
      Key(keychainId: kc1.id, key: .domain(domain: "b.com", scope: .webBrowsers)),
      Key(keychainId: kc2.id, key: .domain(domain: "c.com", scope: .webBrowsers)),
    ])

    // soft-deleted key, should NOT be counted
    let deletedKey = try await self.db.create(Key(
      keychainId: kc1.id,
      key: .domain(domain: "deleted.com", scope: .webBrowsers),
      deletedAt: .reference,
    ))
    _ = deletedKey

    // unrelated keychain on a different child, should NOT be included
    let otherChild = try await self.child()
    let otherKc = try await self.db.create(Keychain(
      parentId: otherChild.parent.model.id,
      name: "other",
    ))
    try await self.db.create(ChildKeychain(
      childId: otherChild.model.id,
      keychainId: otherKc.id,
    ))
    try await self.db.create(Key(
      keychainId: otherKc.id,
      key: .domain(domain: "other.com", scope: .webBrowsers),
    ))

    let result = try await childKeychainSummaries(for: child.model.id, in: self.db)

    expect(result).toHaveCount(2)
    let kc1Result = result.first { $0.id == kc1.id }!
    expect(kc1Result.name).toEqual("kc1")
    expect(kc1Result.description).toEqual("desc")
    expect(kc1Result.parentId).toEqual(parent.model.id)
    expect(kc1Result.numKeys).toEqual(2) // soft-deleted excluded
    expect(kc1Result.schedule).toEqual(kc1Schedule)

    let kc2Result = result.first { $0.id == kc2.id }!
    expect(kc2Result.numKeys).toEqual(1)
    expect(kc2Result.schedule).toBeNil()
  }

  func testReturnsEmptyForChildWithNoKeychains() async throws {
    let child = try await self.child()
    let result = try await childKeychainSummaries(for: child.model.id, in: self.db)
    expect(result).toEqual([])
  }

  func testKeychainWithNoKeysReportsZeroCount() async throws {
    let child = try await self.child()
    let kc = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "empty",
    ))
    try await self.db.create(ChildKeychain(childId: child.model.id, keychainId: kc.id))

    let result = try await childKeychainSummaries(for: child.model.id, in: self.db)
    expect(result).toHaveCount(1)
    expect(result[0].numKeys).toEqual(0)
  }
}
