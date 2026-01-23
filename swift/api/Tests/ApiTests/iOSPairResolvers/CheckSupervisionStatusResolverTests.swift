import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CheckSupervisionStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testNotFound_vendorIdMismatch() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
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
      try await CheckSupervisionStatus.resolve(
        with: .init(
          vendorId: UUID(), // <-- different from device id
          code: code,
        ),
        in: .mock,
      )
    }
    expect(output).toEqual(.notFound)
  }

  func testPending_codeExistsNotClaimed() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
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
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: code),
        in: .mock,
      )
    }
    expect(output).toEqual(.pending)
  }

  func testExpired() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(1),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: code),
        in: .mock,
      )
    }
    expect(output).toEqual(.expired)
  }

  func testClaimed_notYetSupervised() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let uuids = MockUUIDs()
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .mock(uuids)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: code),
        in: .mock,
      )
    }

    expect(output).toEqual(.claimed(.init(
      childId: child.id.rawValue,
      token: uuids[1],
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: .byGertrude(claimCode: code),
    )))
  }

  func testSupervised_notYetProfileInstalled() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: code),
        in: .mock,
      )
    }

    guard case .missingProfile(let data) = output else {
      XCTFail("Expected .missingProfile, got \(output)")
      return
    }
    expect(data.childName).toEqual(child.name)

    let token = try await IOSApp.Token.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    expect(data.token).toEqual(token.value.rawValue)
  }

  func testComplete_allFieldsSet() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let uuids = MockUUIDs()
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
      profileInstalledAt: .reference,
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .mock(uuids)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: code),
        in: .mock,
      )
    }

    expect(output).toEqual(.complete(.init(
      childId: child.id.rawValue,
      token: uuids[1],
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: .byGertrude(claimCode: code),
    )))
  }
}
