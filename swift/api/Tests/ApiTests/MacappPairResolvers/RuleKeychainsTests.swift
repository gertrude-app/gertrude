import Dependencies
import Gertie
import XCTest
import XExpect

@testable import Api

final class RuleKeychainsTests: ApiTestCase, @unchecked Sendable {
  func testReturnsAllKeychainsAndKeysForChild() async throws {
    let child = try await self.child()
    let parent = child.parent

    let kc1 = try await self.db.create(Keychain(parentId: parent.model.id, name: "kc1"))
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

    let kc1KeyA = try await self.db.create(Key(
      keychainId: kc1.id,
      key: .domain(domain: "a.com", scope: .webBrowsers),
    ))
    let kc1KeyB = try await self.db.create(Key(
      keychainId: kc1.id,
      key: .domain(domain: "b.com", scope: .webBrowsers),
    ))
    let kc2KeyC = try await self.db.create(Key(
      keychainId: kc2.id,
      key: .domain(domain: "c.com", scope: .webBrowsers),
    ))

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

    let result = try await ruleKeychains(for: child.model.id, in: self.db)

    expect(result).toHaveCount(2)
    let kc1Result = result.first { $0.id == kc1.id.rawValue }!
    expect(kc1Result.schedule).toEqual(kc1Schedule)
    expect(Set(kc1Result.keys.map(\.id))).toEqual([kc1KeyA.id.rawValue, kc1KeyB.id.rawValue])
    expect(Set(kc1Result.keys.map(\.key)))
      .toEqual([kc1KeyA.key, kc1KeyB.key])

    let kc2Result = result.first { $0.id == kc2.id.rawValue }!
    expect(kc2Result.schedule).toBeNil()
    expect(kc2Result.keys.map(\.id)).toEqual([kc2KeyC.id.rawValue])
    expect(kc2Result.keys.map(\.key)).toEqual([kc2KeyC.key])
  }

  func testReturnsEmptyForChildWithNoKeychains() async throws {
    let child = try await self.child()
    let result = try await ruleKeychains(for: child.model.id, in: self.db)
    expect(result).toEqual([])
  }

  func testKeychainWithNoKeysReturnsEmptyKeyArray() async throws {
    let child = try await self.child()
    let kc = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "empty",
    ))
    try await self.db.create(ChildKeychain(childId: child.model.id, keychainId: kc.id))

    let result = try await ruleKeychains(for: child.model.id, in: self.db)
    expect(result).toHaveCount(1)
    expect(result[0].keys).toEqual([])
  }
}
