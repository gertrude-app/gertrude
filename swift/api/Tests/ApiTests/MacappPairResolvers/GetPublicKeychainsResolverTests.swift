import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class GetPublicKeychainsResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsOnlyPublicKeychains() async throws {
    try await Keychain.query().delete(in: self.db)
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()

    let publicKeychain = try await self.db.create(Keychain(
      parentId: parent1.model.id,
      name: "Safe Sites",
      isPublic: true,
      description: "Kid-friendly websites",
      warning: "Some sites may still have ads",
    ))
    try await self.db.create(Keychain(
      parentId: parent1.model.id,
      name: "My Private Keychain",
      isPublic: false,
    ))
    let publicKeychain2 = try await self.db.create(Keychain(
      parentId: parent2.model.id,
      name: "Educational",
      isPublic: true,
      brandColor: "#1DA1F2",
    ))

    let context = Context(requestId: "", dashboardUrl: "", ipAddress: nil)
    let output = try await GetPublicKeychains.resolve(in: context)

    let sorted = output.sorted { $0.name < $1.name }
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
}
