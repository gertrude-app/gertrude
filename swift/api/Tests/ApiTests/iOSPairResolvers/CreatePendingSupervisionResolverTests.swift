import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CreatePendingSupervisionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_andIdempotency() async throws {
    let vendorId = UUID()
    let fixedCode = Int.random(in: 100_000 ... 999_999)

    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { fixedCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreatePendingSupervision.resolve(
        with: .init(
          vendorId: vendorId,
          deviceType: "iPhone",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(output.code).toEqual(fixedCode)

    let pending = try await IOSApp.PendingSupervision.query()
      .where(.vendorId == vendorId)
      .first(in: self.db)

    expect(pending.code).toEqual(fixedCode)
    expect(pending.vendorId).toEqual(vendorId)
    expect(pending.deviceType).toEqual("iPhone")
    expect(pending.iosVersion).toEqual("18.2")
    expect(pending.appVersion).toEqual("1.0.0")
    expect(pending.claimedChildId).toBeNil()

    let secondOutput = try await withDependencies {
      $0.verificationCode = .init(generate: { Int.random(in: 100_000 ... 999_999) })
      $0.date = .constant(.reference)
    } operation: {
      try await CreatePendingSupervision.resolve(
        with: .init(
          vendorId: vendorId,
          deviceType: "iPhone",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(secondOutput.code).toEqual(fixedCode)
    expect(secondOutput.expiresAt).toEqual(output.expiresAt)

    let count = try await IOSApp.PendingSupervision.query()
      .where(.vendorId == vendorId)
      .count(in: self.db)
    expect(count).toEqual(1)
  }

  func testExpiredRecord_createsNewCode() async throws {
    let vendorId = UUID()
    let expiredDate = Date.reference - .days(8)

    let expired = try await self.db.create(IOSApp.PendingSupervision(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: vendorId,
      deviceType: "iPhone",
      iosVersion: "17.0",
      appVersion: "0.9.0",
      expiresAt: expiredDate,
    ))

    let newCode = Int.random(in: 100_000 ... 999_999)
    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { newCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreatePendingSupervision.resolve(
        with: .init(
          vendorId: vendorId,
          deviceType: "iPad",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(output.code).toEqual(newCode)
    expect(output.code).not.toEqual(111_111)

    let records = try await IOSApp.PendingSupervision.query()
      .where(.vendorId == vendorId)
      .all(in: self.db)
    expect(records).toHaveCount(1)

    let retrieved = try? await self.db.find(expired.id)
    expect(retrieved).toBeNil()
  }
}
