import DuetSQL
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class GetMusicClaimDataResolverTests: ApiTestCase, @unchecked Sendable {
  func testRouteMatches() throws {
    let token = UUID()
    let input = GetMusicClaimData.Input(code: 123_456)
    var request = URLRequest(url: URL(string: "dashboard/GetMusicClaimData")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-AdminToken")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.dashboard(.adminAuthed(token, .getMusicClaimData(input))))
  }

  func testResumeClaimedBySameParentReturnsDone() async throws {
    let parent = try await self.parent()
    try await self.addLightPaidSubscription(for: parent.id)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(.music, device.id, child.id, claimedAt: .reference)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(
      with: .init(code: claim.code),
      in: parent.context,
    )

    expect(output.children).toEqual([])
    expect(output.modelName).toEqual(device.modelName)
    expect(output.iosVersion).toEqual(device.iosVersion)
    expect(output.resumeStep)
      .toEqual(.done(childName: child.name, childId: child.id, deviceId: device.id))
    expect(output.paymentAction).toBeNil()
  }

  func testResumeClaimedBySameParentWithoutMusicInstallThrowsNotFound() async throws {
    let parent = try await self.parent()
    try await self.addLightPaidSubscription(for: parent.id)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(.music, device.id, child.id, claimedAt: .reference)

    try await expectErrorFrom {
      try await GetMusicClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }.toContain("not found")
  }

  func testUnclaimedValidCodeReturnsChildrenAndNoResumeStep() async throws {
    let parent = try await self.parent()
    try await self.addLightPaidSubscription(for: parent.id)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(
      with: .init(code: claim.code),
      in: parent.context,
    )

    expect(output.resumeStep).toBeNil()
    expect(output.children.map(\.id)).toEqual([child.id])
    expect(output.modelName).toEqual(device.modelName)
    expect(output.paymentAction).toBeNil()
  }

  func testUnclaimedCodeForAlreadyBoundDeviceCompletesClaimAndReturnsDone() async throws {
    let parent = try await self.parent()
    try await self.addLightPaidSubscription(for: parent.id)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(.music, device.id)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(
      with: .init(code: claim.code),
      in: parent.context,
    )

    expect(output.resumeStep)
      .toEqual(.done(childName: child.name, childId: child.id, deviceId: device.id))
    expect(output.children).toEqual([])
    let completed = try await Claim.find(code: claim.code, in: self.db)
    expect(completed?.childId).toEqual(child.id)
    expect(completed?.claimedAt).not.toBeNil()
  }

  func testUnclaimedWithoutMusicAccessReturnsPaymentActionAndNoChildren() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(
      with: .init(code: claim.code),
      in: parent.context,
    )

    expect(output.resumeStep).toBeNil()
    expect(output.children).toEqual([])
    expect(output.paymentAction).toEqual(.startCheckout(tier: .light))
  }

  func testUnclaimedBoundDeviceWithoutMusicAccessReturnsPaymentActionAndDoesNotClaim() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(.music, device.id)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(
      with: .init(code: claim.code),
      in: parent.context,
    )

    expect(output.resumeStep).toBeNil()
    expect(output.children).toEqual([])
    expect(output.paymentAction).toEqual(.startCheckout(tier: .light))
    let unchanged = try await Claim.find(code: claim.code, in: self.db)
    expect(unchanged?.claimedAt).toBeNil()
    expect(unchanged?.childId).toBeNil()
  }

  func testUnclaimedPastDueFullReturnsBillingPortalAction() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .full
      $1.stripeStatus = .pastDue
    }
    _ = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(
      with: .init(code: claim.code),
      in: self.context(parent.model),
    )

    expect(output.resumeStep).toBeNil()
    expect(output.children).toEqual([])
    expect(output.paymentAction).toEqual(.openBillingPortal(config: .default))
  }

  func testUnclaimedWithoutMusicInstallThrowsNotFound() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)

    try await expectErrorFrom {
      try await GetMusicClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }.toContain("not found")
  }

  func testClaimedByDifferentParentThrowsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = otherChild.id })
    let claim = try await self.createClaim(.music, device.id, otherChild.id, claimedAt: .reference)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await GetMusicClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }.toContain("not found")
  }
}
