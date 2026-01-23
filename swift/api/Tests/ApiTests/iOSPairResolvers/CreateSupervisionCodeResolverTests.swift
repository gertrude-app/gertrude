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

    expect(device.id.rawValue).toEqual(deviceId)
    expect(device.modelIdentifier).toEqual("iPhone18,2")
    expect(device.iosVersion).toEqual("18.2")
    expect(device.appVersion).toEqual("1.0.0")
    expect(device.childId).toBeNil()

    let supervision = try await device.supervision(in: self.db)!
    expect(supervision.claimCode).toEqual(fixedCode)

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
    let device = try await self.db.create(IOSApp.Device(
      id: .init(deviceId),
      modelIdentifier: "iPhone18,2",
      appVersion: "0.9.0",
      iosVersion: "17.0",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: 111_111,
      claimCodeExpiresAt: .reference - .days(8),
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

    let supervision = try await device.supervision(in: self.db)!
    expect(supervision.claimCode).toEqual(newCode)
  }

  func testExistingDevice_noSupervision_getsSupervisionCreated() async throws {
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
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
          deviceId: device.id.rawValue,
          modelIdentifier: "iPhone18,2",
          iosVersion: "18.2",
          appVersion: "1.0.0",
        ),
        in: .mock,
      )
    }

    expect(output.code).toEqual(newCode)

    let supervision = try await device.supervision(in: self.db)!
    expect(supervision.claimCodeExpiresAt).not.toBeNil()
  }
}
