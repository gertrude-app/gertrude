import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class RecordDeviceUSBConnectionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_setsUdidAndInsertsEvent() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(
          code: claim.code,
          udid: "00008030-001234567890802E",
          modelIdentifier: device.modelIdentifier,
        ),
        in: .mock,
      )
    }

    let updatedSupervision = try await device.supervision(in: self.db)
    expect(updatedSupervision?.udid).toEqual("00008030-001234567890802E")

    let events = try await IOSEvent.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events[0].detail!).toContain("tool_connected")
    expect(events[0].domain).toEqual("supervision")
  }

  func testCodeNotFound_throwsError() async throws {
    try await expectErrorFrom {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(
          code: uniqueClaimCode(),
          udid: "fake-udid",
          modelIdentifier: "iPhone17,1",
        ),
        in: .mock,
      )
    }.toContain("not found")
  }

  func testNewDeviceOverLimit_isBlockedBeforeSupervising() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .light)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    try await self.supervise(child.id, udids: (1 ... 5).map { "udid-\($0)" })
    let (claim, device) = try await self.pendingSupervision(child.id)

    try await expectErrorFrom {
      try await withDependencies { $0.date = .constant(.reference) } operation: {
        try await RecordDeviceUSBConnection.resolve(
          with: .init(code: claim.code, udid: "udid-6", modelIdentifier: device.modelIdentifier),
          in: .mock,
        )
      }
    }.toContain("more iPhones and iPads than Gertrude allows")

    let supervision = try await device.supervision(in: self.db)
    expect(supervision?.udid).toBeNil() // rejected before we record anything
  }

  // the whole reason the check lives here: at usb-connect we know the udid, so a
  // customer re-supervising a phone we've already counted is never false-positived
  func testResupervisingKnownDeviceAtLimit_isAllowed() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .light)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    try await self.supervise(child.id, udids: (1 ... 5).map { "udid-\($0)" })
    let (claim, device) = try await self.pendingSupervision(child.id)

    _ = try await withDependencies { $0.date = .constant(.reference) } operation: {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(code: claim.code, udid: "udid-3", modelIdentifier: device.modelIdentifier),
        in: .mock,
      )
    }

    let supervision = try await device.supervision(in: self.db)
    expect(supervision?.udid).toEqual("udid-3")
  }

  func testComplimentaryAccountIsUncapped() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id, isComplimentary: true))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    try await self.supervise(child.id, udids: (1 ... 25).map { "udid-\($0)" })
    let (claim, device) = try await self.pendingSupervision(child.id)

    _ = try await withDependencies { $0.date = .constant(.reference) } operation: {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(code: claim.code, udid: "udid-26", modelIdentifier: device.modelIdentifier),
        in: .mock,
      )
    }

    let supervision = try await device.supervision(in: self.db)
    expect(supervision?.udid).toEqual("udid-26")
  }

  private func supervise(_ childId: Child.Id, udids: [String]) async throws {
    for udid in udids {
      let device = try await self.db.create(IOSDevice.random { $0.childId = childId })
      try await self.db.create(BlockerApp.Supervision(
        deviceId: device.id,
        udid: udid,
        supervisedAt: .reference,
      ))
    }
  }

  private func pendingSupervision(_ childId: Child.Id) async throws -> (Claim, IOSDevice) {
    let device = try await self.db.create(IOSDevice.random { $0.childId = childId })
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      childId,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))
    return (claim, device)
  }

  func testClaimedExpiredCode_renewsAndRecordsConnection() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      expiresAt: .reference - .days(1), // <-- expired
      claimedAt: .reference - .days(8),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(
          code: claim.code,
          udid: "fake-udid",
          modelIdentifier: device.modelIdentifier,
        ),
        in: .mock,
      )
    }

    let updatedClaim = try await Claim.find(code: claim.code, in: self.db)
    expect(updatedClaim?.expiresAt).toEqual(.reference + .days(21)) // renewed

    let updatedSupervision = try await device.supervision(in: self.db)
    expect(updatedSupervision?.udid).toEqual("fake-udid")
  }
}
