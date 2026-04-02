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
