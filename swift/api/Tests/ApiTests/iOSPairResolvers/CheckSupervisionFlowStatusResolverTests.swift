import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CheckSupervisionFlowStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testNotFound_vendorIdMismatch() async throws {
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
        with: .init(
          vendorId: UUID(), // <-- different from device id
          code: claim.code,
        ),
        in: .mock,
      )
    }
    expect(output).toEqual(.notFound)
  }

  func testPending_codeExistsNotClaimed() async throws {
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.pending)
  }

  func testExpired() async throws {
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      expiresAt: .reference - .days(1),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.expired)
  }

  func testClaimed_notYetSupervised() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let uuids = MockUUIDs()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Install.mock { $0.deviceId = device.id })
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .mock(uuids)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }

    expect(output).toEqual(.claimed(.init(
      childId: child.id.rawValue,
      token: uuids[1],
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: .byGertrude(claimCode: claim.code),
    )))
  }

  func testClaimed_notYetSupervised_expiredCode_renewsAndReturnsClaimed() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let uuids = MockUUIDs()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      expiresAt: .reference - .days(1),
      claimedAt: .reference - .days(8),
    )
    try await self.db.create(BlockerApp.Install.mock { $0.deviceId = device.id })
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .mock(uuids)
    } operation: {
      try await CheckSupervisionFlowStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }

    expect(output).toEqual(.claimed(.init(
      childId: child.id.rawValue,
      token: uuids[1],
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: .byGertrude(claimCode: claim.code),
    )))

    let updatedClaim = try await Claim.find(code: claim.code, in: self.db)
    expect(updatedClaim?.code).toEqual(claim.code)
    expect(updatedClaim?.expiresAt).toEqual(.reference + .days(21)) // renewed
  }

  func testSupervised_notYetProfileInstalled() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      claimedAt: .reference,
    )
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
        with: .init(vendorId: device.id.rawValue, code: claim.code),
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
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let uuids = MockUUIDs()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      claimedAt: .reference,
    )
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
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }

    expect(output).toEqual(.complete(.init(
      childId: child.id.rawValue,
      token: uuids[1],
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: .byGertrude(claimCode: claim.code),
    )))
  }
}
