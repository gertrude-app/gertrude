import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class ClaimIOSDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_newChild_createsChildAndAssignsBlockGroups() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone18,1",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.blockerSupervise, device.id, code: code)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimIOSDevice.resolve(
        with: .init(code: code, child: .newChild(name: "Luke")),
        in: parent.context,
      )
    }

    expect(output.childName).toEqual("Luke")
    expect(output.modelName).toEqual("iPhone 17 Pro")
    expect(output.iosVersion).toEqual("18.2")
    expect(output.code).toEqual(code)

    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(children).toHaveCount(1)
    expect(children[0].name).toEqual("Luke")

    let updatedDevice = try await self.db.find(device.id)
    expect(updatedDevice.childId).toEqual(children[0].id)
    let claim = try await Claim.find(code: code, in: self.db)
    expect(claim?.claimedAt).not.toBeNil()

    let deviceBlockGroups = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(deviceBlockGroups.count).toEqual(8)

    let events = try await IOSEvent.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(events.filter { $0.detail?.contains("code_claimed") == true }).toHaveCount(1)
  }

  func testHappyPath_existingChild_usesExistingChild() async throws {
    let parent = try await self.parent()
    let existingChild = try await self.db.create(Child.random { $0.parentId = parent.id })
    let numPriorChildren = try await Child.query()
      .where(.parentId == parent.id)
      .count(in: self.db)
    expect(numPriorChildren).toEqual(1)

    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPad14,8",
      iosVersion: "26.1",
    ))
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimIOSDevice.resolve(
        with: .init(code: claim.code, child: .existingChild(id: existingChild.id)),
        in: parent.context,
      )
    }

    expect(output.childName).toEqual(existingChild.name)
    expect(output.modelName).toEqual("iPad Air 11-inch (M2)")

    let retrieved = try await self.db.find(device.id)
    expect(retrieved.childId).toEqual(existingChild.id)

    let countAfter = try await Child.query()
      .where(.parentId == parent.id)
      .count(in: self.db)
    expect(countAfter).toEqual(1)
  }

  func testCodeNotFound_throwsError() async throws {
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await ClaimIOSDevice.resolve(
        with: .init(code: Int.random(in: 100_000 ... 999_999), child: .newChild(name: "Test")),
        in: parent.context,
      )
    }.toContain("not found")
  }

  func testCodeExpired_throwsError() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone17,1",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      expiresAt: .reference - .days(1),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimIOSDevice.resolve(
          with: .init(code: claim.code, child: .newChild(name: "Test")),
          in: parent.context,
        )
      }
    }.toContain("expired")
  }

  func testCodeAlreadyClaimedByOtherParent_throwsError() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: otherChild.id,
      modelIdentifier: "iPhone17,1",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      otherChild.id,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let parent = try await self.parent()

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimIOSDevice.resolve(
          with: .init(code: claim.code, child: .newChild(name: "Test")),
          in: parent.context,
        )
      }
    }.toContain("not found")
  }

  func testExistingChildBelongsToOtherParent_throwsError() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone17,1",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimIOSDevice.resolve(
          with: .init(code: claim.code, child: .existingChild(id: otherChild.id)),
          in: parent.context,
        )
      }
    }.toContain("notFound")
  }

  func testLegacyIapCustomerClaimsViaBlockerFunnel_stampsLegacyPaidAt() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))
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

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimIOSDevice.resolve(
        with: .init(code: claim.code, child: .newChild(name: "Luke")),
        in: parent.context,
      )
    }

    let event = try await PodcastEvent.query()
      .where(.deviceId == device.id.rawValue)
      .first(in: self.db)
    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    let stamped = try XCTUnwrap(identity.legacyAmIapPaidAt)
    expect(abs(stamped.timeIntervalSince(event.createdAt)) < 1).toBeTrue()
  }

  func testClaimedCodeDoesNotExpire_andIsIdempotent() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone18,2",
      iosVersion: "18.0",
    ))
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      code: code,
      expiresAt: .reference - .days(30),
      claimedAt: .reference - .days(30),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimIOSDevice.resolve(
        // input child ignored, first claim wins: ------vvvvvvv
        with: .init(code: code, child: .newChild(name: "Ignored")),
        in: parent.context,
      )
    }

    expect(output.childName).toEqual(child.name)
  }
}
