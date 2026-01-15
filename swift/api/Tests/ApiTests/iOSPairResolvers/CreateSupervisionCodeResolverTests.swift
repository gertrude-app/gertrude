import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class CreateSupervisionCodeResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_andIdempotency() async throws {
    let deviceId = UUID()
    let fixedCode = Int.random(in: 100_000 ... 999_999)

    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { fixedCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionCode.resolve(
        with: .init(
          deviceId: deviceId,
          modelIdentifier: "iPhone18,2",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(output.code).toEqual(fixedCode)

    let device = try await IOSApp.Device.query()
      .where(.id == deviceId)
      .first(in: self.db)

    expect(device.supervisionClaimCode).toEqual(fixedCode)
    expect(device.id.rawValue).toEqual(deviceId)
    expect(device.modelIdentifier).toEqual("iPhone18,2")
    expect(device.iosVersion).toEqual("18.2")
    expect(device.appVersion).toEqual("1.0.0")
    expect(device.childId).toBeNil()

    let secondOutput = try await withDependencies {
      $0.verificationCode = .init(generate: { Int.random(in: 100_000 ... 999_999) })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionCode.resolve(
        with: .init(
          deviceId: deviceId,
          modelIdentifier: "iPhone18,2",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(secondOutput.code).toEqual(fixedCode)
    expect(secondOutput.expiresAt).toEqual(output.expiresAt)

    let count = try await IOSApp.Device.query()
      .where(.id == deviceId)
      .count(in: self.db)
    expect(count).toEqual(1)
  }

  func testExpiredCode_createsNewCode() async throws {
    let deviceId = UUID()
    let expiredDate = Date.reference - .days(8)

    try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      modelIdentifier: "iPhone18,2",
      appVersion: "0.9.0",
      iosVersion: "17.0",
      supervisionClaimCode: 111_111,
      claimCodeExpiresAt: expiredDate,
    ))

    let newCode = Int.random(in: 100_000 ... 999_999)
    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { newCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionCode.resolve(
        with: .init(
          deviceId: deviceId,
          modelIdentifier: "iPhone18,2",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(output.code).toEqual(newCode)
    expect(output.code).not.toEqual(111_111)

    let devices = try await IOSApp.Device.query()
      .where(.id == deviceId)
      .all(in: self.db)
    expect(devices).toHaveCount(1)

    let device = devices[0]
    expect(device.supervisionClaimCode).toEqual(newCode)
    expect(device.iosVersion).toEqual("18.2")
    expect(device.appVersion).toEqual("1.0.0")
  }

  func testExistingDevice_noCode_getsCodeAdded() async throws {
    let deviceId = UUID()

    try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      modelIdentifier: "iPhone17,1",
      appVersion: "0.8.0",
      iosVersion: "17.0",
    ))

    let newCode = Int.random(in: 100_000 ... 999_999)
    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { newCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionCode.resolve(
        with: .init(
          deviceId: deviceId,
          modelIdentifier: "iPhone18,2",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(output.code).toEqual(newCode)

    let device = try await self.db.find(IOSApp.Device.Id(deviceId))
    expect(device.supervisionClaimCode).toEqual(newCode)
    expect(device.claimCodeExpiresAt).not.toBeNil()
    expect(device.modelIdentifier).toEqual("iPhone18,2")
    expect(device.iosVersion).toEqual("18.2")
  }
}
