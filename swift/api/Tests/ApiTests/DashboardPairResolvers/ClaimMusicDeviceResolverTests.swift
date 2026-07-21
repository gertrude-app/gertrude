import DuetSQL
import PairQL
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class ClaimMusicDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testRouteMatches() throws {
    let token = UUID()
    let input = ClaimMusicDevice.Input(code: 123_456, child: .newChild(name: "Luke"))
    var request = URLRequest(url: URL(string: "dashboard/ClaimMusicDevice")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-AdminToken")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.dashboard(.adminAuthed(token, .claimMusicDevice(input))))
  }

  func testFreshClaimNewChildSetsDeviceFields() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.unclaimedMusicDevice(code: code)

    let output = try await ClaimMusicDevice.resolve(
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
    expect(output.deviceId).toEqual(device.id) // for the done-screen settings deep link
    expect(output.childId).toEqual(children[0].id)

    let updated = try await self.db.find(device.id)
    expect(updated.childId).toEqual(children[0].id)
    let claim = try await Claim.find(code: code, in: self.db)
    expect(claim?.claimedAt).not.toBeNil()
  }

  func testFreshClaimExistingChildSetsDeviceFields() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.unclaimedMusicDevice(code: code)

    let output = try await ClaimMusicDevice.resolve(
      with: .init(code: code, child: .existingChild(id: child.id)),
      in: parent.context,
    )

    expect(output.childName).toEqual(child.name)
    expect(output.deviceId).toEqual(device.id) // for the done-screen settings deep link
    expect(output.childId).toEqual(child.id)

    let updated = try await self.db.find(device.id)
    expect(updated.childId).toEqual(child.id)
    let claim = try await Claim.find(code: code, in: self.db)
    expect(claim?.claimedAt).not.toBeNil()
  }

  func testAlreadyBoundExpiredClaimThrowsExpiredAndDoesNotClaim() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(
      .music,
      device.id,
      expiresAt: .reference - .days(1),
    )
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    try await expectErrorFrom {
      try await ClaimMusicDevice.resolve(
        with: .init(code: claim.code, child: .newChild(name: "Ignored")),
        in: parent.context,
      )
    }.toContain("expired")

    let unchanged = try await Claim.find(code: claim.code, in: self.db)
    expect(unchanged?.claimedAt).toBeNil()
  }

  func testResumeClaimBySameParentReturnsOutput() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(.music, device.id, child.id, claimedAt: .reference)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await ClaimMusicDevice.resolve(
      with: .init(code: claim.code, child: .newChild(name: "Ignored")),
      in: parent.context,
    )

    expect(output.childName).toEqual(child.name)
    expect(output.modelName).toEqual(device.modelName)
    expect(output.childId).toEqual(child.id)
    expect(output.deviceId).toEqual(device.id)
  }

  func testFreshClaimWithoutMusicAccessRequiresPaymentAndDoesNotClaim() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.unclaimedMusicDevice(code: code)

    do {
      _ = try await ClaimMusicDevice.resolve(
        with: .init(code: code, child: .newChild(name: "Luke")),
        in: parent.context,
      )
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }

    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(children).toHaveCount(0)

    let updated = try await self.db.find(device.id)
    expect(updated.childId).toBeNil()
    let claim = try await Claim.find(code: code, in: self.db)
    expect(claim?.claimedAt).toBeNil()
  }

  func testClaimWithoutMusicInstallThrowsNotFound() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random)
    try await self.createClaim(.music, device.id, code: code)

    try await expectErrorFrom {
      try await ClaimMusicDevice.resolve(
        with: .init(code: code, child: .newChild(name: "Luke")),
        in: parent.context,
      )
    }.toContain("not set up")

    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(children).toHaveCount(0)

    let updated = try await self.db.find(device.id)
    expect(updated.childId).toBeNil()
    let claim = try await Claim.find(code: code, in: self.db)
    expect(claim?.claimedAt).toBeNil()
  }

  func testClaimByDifferentParentThrowsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = otherChild.id })
    let claim = try await self.createClaim(.music, device.id, otherChild.id, claimedAt: .reference)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await ClaimMusicDevice.resolve(
        with: .init(code: claim.code, child: .newChild(name: "Luke")),
        in: parent.context,
      )
    }.toContain("not found")
  }

  func testClaimByDifferentParentWithoutMusicInstallThrowsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = otherChild.id })
    let claim = try await self.createClaim(.music, device.id, otherChild.id, claimedAt: .reference)
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await ClaimMusicDevice.resolve(
        with: .init(code: claim.code, child: .newChild(name: "Luke")),
        in: parent.context,
      )
    }.toContain("not found")
  }
}

extension ClaimMusicDeviceResolverTests {
  @discardableResult
  private func unclaimedMusicDevice(code: Int) async throws -> IOSDevice {
    let device = try await self.db.create(IOSDevice.random)
    try await self.createClaim(.music, device.id, code: code)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    return device
  }
}
