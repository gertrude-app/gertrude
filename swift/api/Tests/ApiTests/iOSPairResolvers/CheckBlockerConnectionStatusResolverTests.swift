import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CheckBlockerConnectionStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testNotFound_noDeviceForCode() async throws {
    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckBlockerConnectionStatus.resolve(
        with: .init(vendorId: UUID(), code: Int.random(in: 100_000 ... 999_999)),
        in: .mock,
      )
    }
    expect(output).toEqual(.notFound)
  }

  func testNotFound_vendorIdMismatch() async throws {
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(.blockerConnect, device.id)

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckBlockerConnectionStatus.resolve(
        with: .init(vendorId: UUID(), code: claim.code), // <-- different from device id
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
    let claim = try await self.createClaim(.blockerConnect, device.id)

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckBlockerConnectionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.pending)
  }

  func testExpired_unclaimedCodePastExpiry() async throws {
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      expiresAt: .reference - .days(1),
    )

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckBlockerConnectionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.expired)
  }

  func testConnected_claimedNoSupervisionRequired() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      child.id,
      claimedAt: .reference,
    )
    let install = try await self.db.create(
      BlockerApp.Install.mock { $0.deviceId = device.id },
    )

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckBlockerConnectionStatus.resolve(
        with: .init(vendorId: device.id.rawValue, code: claim.code),
        in: .mock,
      )
    }

    guard case .connected(let data) = output else {
      XCTFail("Expected .connected, got \(output)")
      return
    }
    expect(data.childId).toEqual(child.id.rawValue)
    expect(data.childName).toEqual(child.name)
    expect(data.supervised).toBeNil() // plain connect is not supervised

    let token = try await BlockerApp.Token.query()
      .where(.installId == install.id)
      .first(in: self.db)
    expect(data.token).toEqual(token.value.rawValue)
  }
}
