import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetBlockerClaimDataResolverTests: ApiTestCase, @unchecked Sendable {
  func testResume_claimedBySameParent_returnsDone() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      child.id,
      claimedAt: .reference,
    )

    let output = try await GetBlockerClaimData.resolve(
      with: .init(code: claim.code),
      in: parent.context,
    )

    expect(output.children).toEqual([])
    expect(output.resumeStep) // carries ids for the done-screen settings deep link
      .toEqual(.done(childName: child.name, childId: child.id, deviceId: device.id))
  }

  func testUnclaimedValidCode_returnsChildrenAndNoResumeStep() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.blockerConnect, device.id)

    let output = try await GetBlockerClaimData.resolve(
      with: .init(code: claim.code),
      in: parent.context,
    )

    expect(output.resumeStep).toBeNil()
    expect(output.children.map(\.id)).toEqual([child.id])
  }

  func testUnclaimedExpiredCode_throwsExpiredError() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      expiresAt: .reference - .days(1),
    )

    try await expectErrorFrom {
      try await GetBlockerClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }.toContain("expired")
  }

  func testClaimedByDifferentParent_throwsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = otherChild.id })
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      otherChild.id,
      claimedAt: .reference,
    )
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await GetBlockerClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }.toContain("not found")
  }
}
