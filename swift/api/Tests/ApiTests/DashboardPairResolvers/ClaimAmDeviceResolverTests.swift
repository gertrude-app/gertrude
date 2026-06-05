import Dependencies
import DuetSQL
import PodcastRoute
import XCTest
import XExpect

@testable import Api

final class ClaimAmDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testFreshClaim_newChild_setsDeviceFields_returnsAmTrial() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.unclaimedAmDevice(code: code)

    let output = try await ClaimAmDevice.resolve(
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
    expect(updated.claimedAt).not.toBeNil()

    let install = try await device.podcastInstall(in: self.db)
    let createdAt = try XCTUnwrap(install?.createdAt)
    expect(output.subscription).toEqual(.amTrial(expiresAt: createdAt + .days(30)))
  }

  func testFreshClaim_activePaidPlan_returnsActive() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id))
    try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .light,
      stripeId: .init("sub_active"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(30),
    ))
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.unclaimedAmDevice(code: code)

    let output = try await ClaimAmDevice.resolve(
      with: .init(code: code, child: .newChild(name: "Luke")),
      in: parent.context,
    )

    expect(output.subscription).toEqual(.active(expiresAt: .reference + .days(30)))
  }

  func testFreshClaim_legacyIapCustomer_stampsPaidAt_returnsGrandfathered() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.unclaimedAmDevice(code: code)
    try await self.db.create(PodcastEvent(
      eventId: "af0a338f",
      kind: .subscription,
      label: "subscribe success",
      detail: "originalID: 123456789012345",
      deviceId: device.id.rawValue,
      modelIdentifier: device.modelIdentifier,
      appVersion: "1.4.0",
      iosVersion: device.iosVersion,
    ))

    let output = try await ClaimAmDevice.resolve(
      with: .init(code: code, child: .newChild(name: "Luke")),
      in: parent.context,
    )

    let event = try await PodcastEvent.query()
      .where(.deviceId == device.id.rawValue)
      .first(in: self.db)
    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    let stamped = try XCTUnwrap(identity.legacyAmIapPaidAt)
    expect(abs(stamped.timeIntervalSince(event.createdAt)) < 1).toBeTrue()

    guard case .legacyGrandfathered = output.subscription else {
      return XCTFail("expected .legacyGrandfathered, got \(output.subscription)")
    }
  }

  func testClaimByDifferentParent_throwsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = otherChild.id
      $0.claimCode = code
      $0.claimedAt = .reference
    })
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await ClaimAmDevice.resolve(
        with: .init(code: code, child: .newChild(name: "Test")),
        in: parent.context,
      )
    }.toContain("not found")
  }
}

extension ClaimAmDeviceResolverTests {
  @discardableResult
  private func unclaimedAmDevice(code: Int) async throws -> IOSDevice {
    let device = try await self.db.create(IOSDevice.random {
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference + .days(7)
    })
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))
    return device
  }
}
