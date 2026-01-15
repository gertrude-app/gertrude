import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CheckSupervisionStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testNotFound_vendorIdMismatch() async throws {
    let deviceId = UUID()
    try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      supervisionClaimCode: Int.random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(
          vendorId: UUID(), // <-- different from device id
          code: Int.random(in: 100_000 ... 999_999),
        ),
        in: .mock,
      )
    }
    expect(output).toEqual(.notFound)
  }

  func testPending_codeExistsNotClaimed() async throws {
    let deviceId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      supervisionClaimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: deviceId, code: code),
        in: .mock,
      )
    }
    expect(output).toEqual(.pending)
  }

  func testExpired() async throws {
    let deviceId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      supervisionClaimCode: code,
      claimCodeExpiresAt: .reference - .days(1),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: deviceId, code: code),
        in: .mock,
      )
    }
    expect(output).toEqual(.expired)
  }

  func testClaimed_notYetSupervised() async throws {
    let deviceId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      isSupervised: false,
      supervisionClaimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: deviceId, code: code),
        in: .mock,
      )
    }
    expect(output).toEqual(.claimed(.init(childName: child.name)))
  }

  func testSupervised_notYetProfileInstalled() async throws {
    let deviceId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      isSupervised: true,
      isProfileInstalled: false,
      supervisionClaimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: deviceId, code: code),
        in: .mock,
      )
    }

    guard case .supervised(let data) = output else {
      XCTFail("Expected .supervised, got \(output)")
      return
    }
    expect(data.childName).toEqual(child.name)
    // TODO: superios task 07 will handle this
    // expect(data.profileUrl).toEqual(???)

    let token = try await IOSApp.Token.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    expect(data.deviceToken).toEqual(token.value.rawValue)
  }

  func testComplete_allFieldsSet() async throws {
    let deviceId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      isSupervised: true,
      isProfileInstalled: true,
      supervisionClaimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: deviceId, code: code),
        in: .mock,
      )
    }
    expect(output).toEqual(.complete)
  }
}
