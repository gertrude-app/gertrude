import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CheckSupervisionStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testNotFound_vendorIdMismatch() async throws {
    let pending = try await self.db.create(IOSApp.PendingSupervision(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: UUID(), // <-- different vendorId...
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      expiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(
          vendorId: UUID(), // <-- from this
          code: pending.code,
        ),
        in: .mock,
      )
    }
    expect(output).toEqual(.notFound)
  }

  func testPending_codeExistsNotClaimed() async throws {
    let vendorId = UUID()
    let pending = try await self.db.create(IOSApp.PendingSupervision(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: vendorId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      expiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: vendorId, code: pending.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.pending)
  }

  func testExpired() async throws {
    let vendorId = UUID()
    let pending = try await self.db.create(IOSApp.PendingSupervision(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: vendorId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      expiresAt: .reference - .days(1),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: vendorId, code: pending.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.expired)
  }

  func testClaimed_notYetSupervised() async throws {
    let vendorId = UUID()
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    _ = try await self.db.create(IOSApp.Device(
      childId: child.id,
      vendorId: .init(vendorId),
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      isSupervised: false, // <-- not yet supervised
    ))
    let pending = try await self.db.create(IOSApp.PendingSupervision(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: vendorId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      claimedChildId: child.id,
      expiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: vendorId, code: pending.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.claimed(.init(childName: child.name)))
  }

  func testSupervised_notYetProfileInstalled() async throws {
    let vendorId = UUID()
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSApp.Device(
      childId: child.id,
      vendorId: .init(vendorId),
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      isSupervised: true, // <-- supervised...
      isProfileInstalled: false, // <-- but profile not yet installed
    ))
    let pending = try await self.db.create(IOSApp.PendingSupervision(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: vendorId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      claimedChildId: child.id,
      expiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: vendorId, code: pending.code),
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
    let vendorId = UUID()
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    _ = try await self.db.create(IOSApp.Device(
      childId: child.id,
      vendorId: .init(vendorId),
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
      isSupervised: true,
      isProfileInstalled: true,
    ))
    let pending = try await self.db.create(IOSApp.PendingSupervision(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: vendorId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      claimedChildId: child.id,
      expiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await CheckSupervisionStatus.resolve(
        with: .init(vendorId: vendorId, code: pending.code),
        in: .mock,
      )
    }
    expect(output).toEqual(.complete)
  }
}
