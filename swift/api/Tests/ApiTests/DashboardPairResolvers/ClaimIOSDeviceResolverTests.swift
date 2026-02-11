import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class ClaimIOSDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_newChild_createsChildAndAssignsBlockGroups() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone18,1",
      appVersion: "1.5.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

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

    let supervision = try await IOSApp.Supervision.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    expect(supervision.claimedAt).not.toBeNil()

    let deviceBlockGroups = try await IOSApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(deviceBlockGroups.count).toEqual(9)

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

    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPad14,8",
      appVersion: "1.5.0",
      iosVersion: "26.1",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await ClaimIOSDevice.resolve(
        with: .init(code: code, child: .existingChild(id: existingChild.id)),
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
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone17,1",
      appVersion: "1.5.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(1),
    ))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimIOSDevice.resolve(
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
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: otherChild.id,
      modelIdentifier: "iPhone17,1",
      appVersion: "1.5.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))

    let parent = try await self.parent()

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimIOSDevice.resolve(
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
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone17,1",
      appVersion: "1.5.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await ClaimIOSDevice.resolve(
          with: .init(code: code, child: .existingChild(id: otherChild.id)),
          in: parent.context,
        )
      }
    }.toContain("notFound")
  }

  func testClaimedCodeDoesNotExpire_andIsIdempotent() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone18,2",
      appVersion: "1.0.0",
      iosVersion: "18.0",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(30),
      claimedAt: .reference - .days(30),
    ))

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
