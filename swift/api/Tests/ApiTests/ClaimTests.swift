import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class ClaimTests: ApiTestCase, @unchecked Sendable {
  func testEnsureActive_createsAndIsIdempotent() async throws {
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let fixedCode = Int.random(in: 100_000 ... 999_999)

    let first = try await withDependencies {
      $0.verificationCode = .init(generate: { fixedCode })
      $0.date = .constant(.reference)
    } operation: {
      try await Claim.ensureActive(intent: .blockerConnect, deviceId: device.id, in: self.db)
    }

    expect(first.code).toEqual(fixedCode)
    expect(first.intent).toEqual(.blockerConnect)
    expect(first.deviceId).toEqual(device.id)
    expect(first.expiresAt).toEqual(.reference + .days(7))

    let second = try await withDependencies {
      $0.verificationCode = .init(generate: { Int.random(in: 100_000 ... 999_999) })
      $0.date = .constant(.reference)
    } operation: {
      try await Claim.ensureActive(intent: .blockerConnect, deviceId: device.id, in: self.db)
    }
    expect(second.id).toEqual(first.id) // idempotent, same active claim

    let count = try await Claim.query().where(.deviceId == device.id).count(in: self.db)
    expect(count).toEqual(1)
  }

  func testActiveLookup_andComplete() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let code = Int.random(in: 100_000 ... 999_999)
    _ = try await withDependencies {
      $0.verificationCode = .init(generate: { code })
      $0.date = .constant(.reference)
    } operation: {
      try await Claim.ensureActive(intent: .blockerConnect, deviceId: device.id, in: self.db)
    }

    try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      guard var claim = try await Claim.find(code: code, in: self.db) else {
        XCTFail("expected to find claim")
        return
      }
      expect(claim.code).toEqual(code)
      try await claim.complete(childId: child.id, in: self.db)
    }

    // a claimed code stays resolvable (for resume), now carrying the binding
    let afterComplete = try await Claim.find(code: code, in: self.db)
    expect(afterComplete?.childId).toEqual(child.id)
    expect(afterComplete?.claimedAt).not.toBeNil()
  }
}
