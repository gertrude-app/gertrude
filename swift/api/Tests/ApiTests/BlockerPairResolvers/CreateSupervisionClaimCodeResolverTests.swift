import BlockerRoute
import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class CreateSupervisionClaimCodeResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_andIdempotency() async throws {
    let deviceId = UUID()
    let fixedCode = uniqueClaimCode()

    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { fixedCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionClaimCode.resolve(
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

    let device = try await IOSDevice.query()
      .where(.id == deviceId)
      .first(in: self.db)

    expect(device.id.rawValue).toEqual(deviceId)
    expect(device.modelIdentifier).toEqual("iPhone18,2")
    expect(device.iosVersion).toEqual("18.2")
    expect(device.childId).toBeNil()
    let claim = try await Claim.find(code: fixedCode, in: self.db)
    expect(claim?.intent).toEqual(.blockerSupervise)
    expect(claim?.deviceId).toEqual(device.id)
    let install = try await device.blockerInstall(in: self.db)
    expect(install.appVersion).toEqual("1.0.0")

    let supervision = try await device.supervision(in: self.db)!
    expect(supervision.deviceId).toEqual(device.id)

    let secondOutput = try await withDependencies {
      $0.verificationCode = .init(generate: { uniqueClaimCode() })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionClaimCode.resolve(
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

    let count = try await IOSDevice.query()
      .where(.id == deviceId)
      .count(in: self.db)
    expect(count).toEqual(1)
  }

  func testExpiredCode_createsNewCode() async throws {
    let deviceId = UUID()
    let device = try await self.db.create(IOSDevice(
      id: .init(deviceId),
      modelIdentifier: "iPhone18,2",
      iosVersion: "17.0",
    ))
    let expiredCode = uniqueClaimCode()
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      code: expiredCode,
      expiresAt: .reference - .days(8),
    ) // <-- expired
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let newCode = uniqueClaimCode()
    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { newCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionClaimCode.resolve(
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
    expect(output.code).not.toEqual(expiredCode)

    let claim = try await Claim.find(code: newCode, in: self.db)
    expect(claim?.deviceId).toEqual(device.id)
  }

  func testExistingDevice_noSupervision_getsSupervisionCreated() async throws {
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      modelIdentifier: "iPhone17,1",
      iosVersion: "17.0",
    ))

    let newCode = uniqueClaimCode()
    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { newCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateSupervisionClaimCode.resolve(
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

    let claim = try await Claim.find(code: newCode, in: self.db)
    expect(claim?.deviceId).toEqual(device.id)
    expect(claim?.intent).toEqual(.blockerSupervise)

    let supervision = try await device.supervision(in: self.db)!
    expect(supervision.deviceId).toEqual(device.id)
  }
}
