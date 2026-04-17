import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class GetOnboardingConfigResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsOnlyPublicKeychains() async throws {
    try await Keychain.query().delete(in: self.db)
    try await AlwaysBlockedGroup.query().delete(in: self.db)
    let child = try await self.child().withDevice()
    let otherParent = try await self.parent()

    let publicKeychain = try await self.db.create(Keychain(
      parentId: otherParent.model.id,
      name: "Safe Sites",
      isPublic: true,
      description: "Kid-friendly websites",
      warning: "Some sites may still have ads",
    ))
    try await self.db.create(Keychain(
      parentId: otherParent.model.id,
      name: "My Private Keychain",
      isPublic: false,
    ))
    let publicKeychain2 = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "Educational",
      isPublic: true,
      brandColor: "#1DA1F2",
    ))

    let output = try await GetOnboardingConfig.resolve(in: context(child))

    let sorted = output.publicKeychains.sorted { $0.name < $1.name }
    expect(sorted).toHaveCount(2)

    expect(sorted[0].id).toEqual(publicKeychain2.id.rawValue)
    expect(sorted[0].name).toEqual("Educational")
    expect(sorted[0].description).toBeNil()
    expect(sorted[0].warning).toBeNil()
    expect(sorted[0].brandColor).toEqual("#1DA1F2")

    expect(sorted[1].id).toEqual(publicKeychain.id.rawValue)
    expect(sorted[1].name).toEqual("Safe Sites")
    expect(sorted[1].description).toEqual("Kid-friendly websites")
    expect(sorted[1].warning).toEqual("Some sites may still have ads")
    expect(sorted[1].brandColor).toBeNil()
  }

  func testReturnsAllAlwaysBlockedGroups() async throws {
    try await Keychain.query().delete(in: self.db)
    try await AlwaysBlockedGroup.query().delete(in: self.db)
    let child = try await self.child().withDevice()

    let adult = try await self.db.create(AlwaysBlockedGroup(
      name: "Adult content",
      description: "Adult short",
      longDescription: "Adult long description",
    ))
    let misc = try await self.db.create(AlwaysBlockedGroup(
      name: "Miscellaneous",
      description: "Misc short",
      longDescription: "Misc long description",
    ))

    let output = try await GetOnboardingConfig.resolve(in: context(child))

    let sorted = output.alwaysBlocked.groups.sorted { $0.name < $1.name }
    expect(sorted).toHaveCount(2)

    expect(sorted[0].id).toEqual(adult.id.rawValue)
    expect(sorted[0].name).toEqual("Adult content")
    expect(sorted[0].description).toEqual("Adult short")
    expect(sorted[0].longDescription).toEqual("Adult long description")

    expect(sorted[1].id).toEqual(misc.id.rawValue)
    expect(sorted[1].name).toEqual("Miscellaneous")
    expect(sorted[1].description).toEqual("Misc short")
    expect(sorted[1].longDescription).toEqual("Misc long description")
  }

  func testPreselectsOnlyRecommendedGroups() async throws {
    try await Keychain.query().delete(in: self.db)
    try await AlwaysBlockedGroup.query().delete(in: self.db)
    let child = try await self.child().withDevice()

    let recommended1 = try await self.db.create(AlwaysBlockedGroup(
      name: "Adult content",
      description: "short",
      longDescription: "long",
      recommended: true,
    ))
    let recommended2 = try await self.db.create(AlwaysBlockedGroup(
      name: "Gambling",
      description: "short",
      longDescription: "long",
      recommended: true,
    ))
    let notRecommended = try await self.db.create(AlwaysBlockedGroup(
      name: "Miscellaneous",
      description: "short",
      longDescription: "long",
      recommended: false,
    ))

    let output = try await GetOnboardingConfig.resolve(in: context(child))

    let preselected = Set(output.alwaysBlocked.preselected)
    expect(preselected == Set([recommended1.id.rawValue, recommended2.id.rawValue]))
      .toEqual(true)
    expect(preselected.contains(notRecommended.id.rawValue)).toEqual(false)
  }
}
