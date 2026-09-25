import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetAccountBlockerClaimDataResolverTests: ApiTestCase, @unchecked Sendable {
  func testUnclaimedCode_returnsDeviceArtworkAndOwnedPeople() async throws {
    let parent = try await self.parent()
    let jude = try await self.db.create(Child(
      parentId: parent.id,
      name: "Jude",
      relationship: .child,
    ))
    let mika = try await self.db.create(Child(
      parentId: parent.id,
      name: "Mika",
      relationship: .peer,
    ))
    let otherParent = try await self.parent()
    _ = try await self.db.create(Child(parentId: otherParent.id, name: "Other"))
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      modelIdentifier: "iPhone16,1",
      iosVersion: "26.0",
    ))
    let claim = try await self.createClaim(.blockerConnect, device.id)

    let output = try await GetAccountBlockerClaimData.resolve(
      with: .init(code: claim.code),
      in: self.accountContext(parent),
    )

    expect(output.modelName).toEqual(device.modelName)
    expect(output.modelIdentifier).toEqual(device.modelIdentifier)
    expect(output.deviceType).toEqual(device.deviceType)
    expect(output.iosVersion).toEqual(device.iosVersion)
    expect(output.people.map(\.id)).toEqual([jude.id, mika.id])
    expect(output.people.map(\.name)).toEqual(["Jude", "Mika"])
    expect(output.people.map(\.relationship)).toEqual([.child, .peer])
    expect(output.assignment).toBeNil()
  }

  func testClaimedCode_resumesForSameParentEvenAfterExpiry() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let device = try await self.db.create(IOSDevice.random { $0.childId = person.id })
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      person.id,
      expiresAt: .reference - .days(1),
      claimedAt: .reference - .days(1),
    )

    let output = try await GetAccountBlockerClaimData.resolve(
      with: .init(code: claim.code),
      in: self.accountContext(parent),
    )

    expect(output.people).toBeEmpty()
    expect(output.modelIdentifier).toEqual(device.modelIdentifier)
    expect(output.assignment?.personId).toEqual(person.id)
    expect(output.assignment?.personName).toEqual(person.name)
    expect(output.assignment?.deviceId).toEqual(device.id)
  }

  func testBoundUnclaimedCode_completesClaimAndSeedsBlockGroups() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let device = try await self.db.create(IOSDevice.random { $0.childId = person.id })
    let claim = try await self.createClaim(.blockerConnect, device.id)

    let output = try await GetAccountBlockerClaimData.resolve(
      with: .init(code: claim.code),
      in: self.accountContext(parent),
    )

    expect(output.assignment?.personId).toEqual(person.id)
    let completed = try await Claim.find(code: claim.code, in: self.db)
    expect(completed?.childId).toEqual(person.id)
    expect(completed?.claimedAt).not.toBeNil()
    let blockGroups = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(blockGroups.isEmpty).toBeFalse()
  }

  func testExpiredUnclaimedCode_isRejected() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      expiresAt: .reference - .days(1),
    )

    try await expectErrorFrom {
      try await GetAccountBlockerClaimData.resolve(
        with: .init(code: claim.code),
        in: self.accountContext(parent),
      )
    }.toContain("expired")
  }

  func testClaimedByDifferentAccount_isNotFound() async throws {
    let owner = try await self.parent()
    let person = try await self.db.create(Child(parentId: owner.id, name: "Jude"))
    let device = try await self.db.create(IOSDevice.random { $0.childId = person.id })
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      person.id,
      claimedAt: .reference,
    )
    let otherAccount = try await self.parent()

    try await expectErrorFrom {
      try await GetAccountBlockerClaimData.resolve(
        with: .init(code: claim.code),
        in: self.accountContext(otherAccount),
      )
    }.toContain("not found")
  }

  func testWrongIntentCode_isRejected() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)

    try await expectErrorFrom {
      try await GetAccountBlockerClaimData.resolve(
        with: .init(code: claim.code),
        in: self.accountContext(parent),
      )
    }.toContain("not Gertrude Blocker")
  }

  func testMissingCode_isNotFound() async throws {
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await GetAccountBlockerClaimData.resolve(
        with: .init(code: uniqueClaimCode()),
        in: self.accountContext(parent),
      )
    }.toContain("not found")
  }
}
