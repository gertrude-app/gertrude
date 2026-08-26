import DuetSQL
import XCTest
import XExpect

@testable import Api

final class ClaimBlockerDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testFreshClaim_newChild_setsDeviceFields_seedsBlockGroups() async throws {
    let parent = try await self.parent()
    let code = uniqueClaimCode()
    let device = try await self.db.create(IOSDevice.random)
    try await self.createClaim(.blockerConnect, device.id, code: code)

    let before = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(before.isEmpty).toBeTrue()

    let output = try await ClaimBlockerDevice.resolve(
      with: .init(code: code, child: .newChild(name: "Luke")),
      in: parent.context,
    )

    expect(output.childName).toEqual("Luke")
    expect(output.modelName).toEqual(device.modelName)
    expect(output.iosVersion).toEqual(device.iosVersion)
    expect(output.code).toEqual(code)

    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(children).toHaveCount(1)

    let updated = try await self.db.find(device.id)
    expect(updated.childId).toEqual(children[0].id)
    let claim = try await Claim.find(code: code, in: self.db)
    expect(claim?.claimedAt).not.toBeNil()

    expect(output.deviceId).toEqual(device.id) // for the done-screen settings deep link
    expect(output.childId).toEqual(children[0].id)

    let after = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(after.isEmpty).toBeFalse() // connect seeds default block groups
  }

  func testClaimByDifferentParent_throwsCodeNotFound() async throws {
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
      try await ClaimBlockerDevice.resolve(
        with: .init(code: claim.code, child: .newChild(name: "Test")),
        in: parent.context,
      )
    }.toContain("not found")
  }
}
