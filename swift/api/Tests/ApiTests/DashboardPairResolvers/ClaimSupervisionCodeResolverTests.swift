import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class ClaimSupervisionCodeResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_newChild_createsChildDeviceTokenAndBlockGroups() async throws {
    let parent = try await self.parent()
    let vendorId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    let pending = try await self.db.create(IOSApp.PendingSupervision(
      code: code,
      vendorId: vendorId,
      modelIdentifier: "iPhone18,1",
      iosVersion: "18.2",
      appVersion: "1.5.0",
      expiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimSupervisionCode.resolve(
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

    let device = try await IOSApp.Device.query()
      .where(.vendorId == vendorId)
      .first(in: self.db)
    expect(device.childId).toEqual(children[0].id)
    expect(device.modelIdentifier).toEqual("iPhone18,1")
    expect(device.iosVersion).toEqual("18.2")
    expect(device.supervisedAt).toBeNil()

    let deviceBlockGroups = try await IOSApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(deviceBlockGroups.count).toEqual(9)

    let updatedPending = try await self.db.find(pending.id)
    expect(updatedPending.claimedChildId).toEqual(children[0].id)
  }

  func testHappyPath_existingChild_usesExistingChild() async throws {
    let parent = try await self.parent()
    let existingChild = try await self.db.create(Child.random { $0.parentId = parent.id })
    let numPriorChildren = try await Child.query()
      .where(.parentId == parent.id)
      .count(in: self.db)
    expect(numPriorChildren).toEqual(1)

    let vendorId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.PendingSupervision(
      code: code,
      vendorId: vendorId,
      modelIdentifier: "iPad14,8",
      iosVersion: "26.1",
      appVersion: "1.5.0",
      expiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimSupervisionCode.resolve(
        with: .init(code: code, child: .existingChild(id: existingChild.id)),
        in: parent.context,
      )
    }

    expect(output.childName).toEqual(existingChild.name)
    expect(output.modelName).toEqual("iPad Air 11-inch (M2)")

    let device = try await IOSApp.Device.query()
      .where(.vendorId == vendorId)
      .first(in: self.db)
    expect(device.childId).toEqual(existingChild.id)

    let countAfter = try await Child.query()
      .where(.parentId == parent.id)
      .count(in: self.db)
    expect(countAfter).toEqual(1)
  }

  func testCodeNotFound_throwsError() async throws {
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await ClaimSupervisionCode.resolve(
        with: .init(code: Int.random(in: 100_000 ... 999_999), child: .newChild(name: "Test")),
        in: parent.context,
      )
    }.toContain("not found")
  }

  func testCodeExpired_throwsError() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.PendingSupervision(
      code: code,
      vendorId: UUID(),
      modelIdentifier: "iPhone18,1",
      iosVersion: "18.0",
      appVersion: "1.0.0",
      expiresAt: .reference - .days(1),
    ))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimSupervisionCode.resolve(
          with: .init(code: code, child: .newChild(name: "Test")),
          in: parent.context,
        )
      }
    }.toContain("expired")
  }

  func testCodeAlreadyClaimedByOtherParent_throwsError() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.PendingSupervision(
      code: code,
      vendorId: UUID(),
      modelIdentifier: "iPhone18,2",
      iosVersion: "18.0",
      appVersion: "1.0.0",
      claimedChildId: otherChild.id, // <-- already claimed by other parent
      expiresAt: .reference + .days(7),
    ))

    let parent = try await self.parent()

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimSupervisionCode.resolve(
          with: .init(code: code, child: .newChild(name: "Test")),
          in: parent.context,
        )
      }
    }.toContain("not found")
  }

  func testExistingChildBelongsToOtherParent_throwsError() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.PendingSupervision(
      code: code,
      vendorId: UUID(),
      modelIdentifier: "iPhone18,2",
      iosVersion: "18.0",
      appVersion: "1.0.0",
      expiresAt: .reference + .days(7),
    ))

    let parent = try await self.parent()

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimSupervisionCode.resolve(
          with: .init(code: code, child: .existingChild(id: otherChild.id)),
          in: parent.context,
        )
      }
    }.toContain("notFound")
  }

  func testDuplicateDevice_reusesExistingDevice() async throws {
    let parent = try await self.parent()
    let existingChild = try await self.db.create(Child.random { $0.parentId = parent.id })
    let vendorId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)

    let existingDevice = try await self.db.create(IOSApp.Device(
      childId: existingChild.id,
      vendorId: .init(vendorId),
      modelIdentifier: "iPhone18,2",
      appVersion: "1.5.1",
      iosVersion: "17.0",
    ))

    try await self.db.create(IOSApp.PendingSupervision(
      code: code,
      vendorId: vendorId, // <-- we already have a device with this vendorId...
      modelIdentifier: "iPhone18,2",
      iosVersion: "18.0",
      appVersion: "1.4.9",
      expiresAt: .reference + .days(7),
    ))

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimSupervisionCode.resolve(
        with: .init(code: code, child: .existingChild(id: existingChild.id)),
        in: parent.context,
      )
    }

    let devices = try await IOSApp.Device.query()
      .where(.vendorId == vendorId)
      .all(in: self.db)
    expect(devices.map(\.id)).toEqual([existingDevice.id]) // ...so we reuse it

    let updatedPending = try await IOSApp.PendingSupervision.query()
      .where(.code == code)
      .first(in: self.db)
    expect(updatedPending.claimedChildId).toEqual(existingChild.id)
  }

  func testClaimedCodeDoesNotExpire_andIsIdempotent() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let vendorId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.Device(
      childId: child.id,
      vendorId: .init(vendorId),
      modelIdentifier: "iPhone18,2",
      appVersion: "1.0.0",
      iosVersion: "18.0",
    ))
    try await self.db.create(IOSApp.PendingSupervision(
      code: code,
      vendorId: vendorId,
      modelIdentifier: "iPhone18,2",
      iosVersion: "18.0",
      appVersion: "1.0.0",
      claimedChildId: child.id, // <-- already claimed, expiration doesn't matter
      expiresAt: .reference - .days(30),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimSupervisionCode.resolve(
        // input child ignored, first claim wins: ------vvvvvvv
        with: .init(code: code, child: .newChild(name: "Ignored")),
        in: parent.context,
      )
    }

    expect(output.childName).toEqual(child.name)
  }
}
