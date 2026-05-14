import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CheckSupervisionFlowStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testNotFound_vendorIdMismatch() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
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
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: code),
        in: .mock,
      )
    }
    expect(output).toEqual(.pending)
  }

  func testExpired() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(1),
    ))
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
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
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))
    try await self.db.create(BlockerApp.Install.mock { $0.deviceId = device.id })
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .mock(uuids)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
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
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))
    let install = try await self.db.create(
      BlockerApp.Install.mock { $0.deviceId = device.id },
    )
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference,
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: code),
        in: .mock,
      )
    }

    guard case .missingProfile(let data) = output else {
      XCTFail("Expected .missingProfile, got \(output)")
      return
    }
    expect(data.childName).toEqual(child.name)

    let token = try await BlockerApp.Token.query()
      .where(.installId == install.id)
      .first(in: self.db)
    expect(data.token).toEqual(token.value.rawValue)
  }

  func testComplete_allFieldsSet() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let uuids = MockUUIDs()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))
    try await self.db.create(BlockerApp.Install.mock { $0.deviceId = device.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference,
      profileInstalledAt: .reference,
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .mock(uuids)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
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
