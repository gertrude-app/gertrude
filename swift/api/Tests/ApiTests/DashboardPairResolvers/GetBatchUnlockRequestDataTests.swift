import XCTest
import XExpect

@testable import Api

final class GetBatchUnlockRequestDataTests: ApiTestCase, @unchecked Sendable {
  func testReturnsAllPendingRequestsWithoutServerSideDedup() async throws {
    let child = try await self.child().withDevice()

    let first = UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
      ipAddress: "1.2.3.4",
      status: .pending,
    )

    let second = UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
      ipAddress: "1.2.3.4",
      requestComment: "please unlock",
      status: .pending,
    )

    let third = UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
      ipAddress: "5.6.7.8",
      status: .pending,
    )

    try await self.db.create(first)
    try await self.db.create(second)
    try await self.db.create(third)

    let keychain = try await self.db.create(Keychain(
      parentId: child.parent.id,
      name: "Test Keychain",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: keychain.id,
    ))

    let output = try await GetBatchUnlockRequestData.resolve(
      with: child.model.id,
      in: context(child.parent),
    )

    expect(output.requests).toHaveCount(3)
    let ids = Set(output.requests.map(\.id))
    expect(ids).toEqual([first.id, second.id, third.id])
  }

  func testCatalogedAppNameAndIconTakePrecedence() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: AppBundleId.self)
    await clearCachedAppIdManifest()

    let child = try await self.child().withDevice()

    // an identified app whose curated name differs from the Mac's real name
    let identified = try await self.db.create(IdentifiedApp(
      name: "Unity",
      slug: "unity-hub",
      launchable: true,
    ))
    // identified catalog enumerates both the clean + team-prefixed forms (as prod does)
    try await self.db.create(AppBundleId(
      identifiedAppId: identified.id,
      bundleId: "com.unity3d.unityhub",
    ))
    try await self.db.create(AppBundleId(
      identifiedAppId: identified.id,
      bundleId: "9QW8UQUTAA.com.unity3d.unityhub",
    ))
    // cataloged app carries the real Mac display name + an icon
    try await self.db.create(CatalogedApp(
      bundleId: "com.unity3d.unityhub",
      name: "Unity Hub",
      iconContentHash: "abc123",
    ))

    // request arrives with a team-id prefix — must still match the cataloged row
    let request = UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: "9QW8UQUTAA.com.unity3d.unityhub",
      hostname: "core.cloud.unity3d.com",
      status: .pending,
    )
    try await self.db.create(request)

    let output = try await GetBatchUnlockRequestData.resolve(
      with: child.model.id,
      in: context(child.parent),
    )

    let req = try XCTUnwrap(output.requests.first)
    expect(req.appName).toEqual("Unity Hub") // cataloged name wins over "Unity"
    expect(req.appIconHash).toEqual("abc123")
    expect(req.appSlug).toEqual("unity-hub") // identified slug still drives scope
  }

  func testUncatalogedAppFallsBackToIdentifiedName() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: AppBundleId.self)
    try await self.db.delete(all: CatalogedApp.self)
    await clearCachedAppIdManifest()

    let child = try await self.child().withDevice()

    let identified = try await self.db.create(IdentifiedApp(
      name: "Firefox",
      slug: "firefox",
      launchable: true,
    ))
    try await self.db.create(AppBundleId(
      identifiedAppId: identified.id,
      bundleId: "org.mozilla.firefox",
    ))

    let request = UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: "org.mozilla.firefox",
      hostname: "example.com",
      status: .pending,
    )
    try await self.db.create(request)

    let output = try await GetBatchUnlockRequestData.resolve(
      with: child.model.id,
      in: context(child.parent),
    )

    let req = try XCTUnwrap(output.requests.first)
    expect(req.appName).toEqual("Firefox") // no cataloged row → identified name
    expect(req.appIconHash).toBeNil()
  }

  func testPublicKeychainOwnedByOtherParentExcludedFromKeychains() async throws {
    let child = try await self.child().withDevice()

    let request = UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
      status: .pending,
    )
    try await self.db.create(request)

    let ownKeychain = try await self.db.create(Keychain(
      parentId: child.parent.id,
      name: "Parent's Keychain",
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: ownKeychain.id,
    ))

    let otherParent = try await self.parent()
    let publicKeychain = try await self.db.create(Keychain(
      parentId: otherParent.id,
      name: "Public Keychain",
      isPublic: true,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: publicKeychain.id,
    ))

    let output = try await GetBatchUnlockRequestData.resolve(
      with: child.model.id,
      in: context(child.parent),
    )

    expect(output.keychains).toHaveCount(1)
    expect(output.keychains.first?.id).toEqual(ownKeychain.id)
  }
}
