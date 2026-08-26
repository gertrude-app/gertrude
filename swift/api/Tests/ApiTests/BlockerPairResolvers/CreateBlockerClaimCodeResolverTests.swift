import BlockerRoute
import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class CreateBlockerClaimCodeResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_createsCodeWithoutSupervision() async throws {
    let deviceId = UUID()
    let fixedCode = uniqueClaimCode()

    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { fixedCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateBlockerClaimCode.resolve(
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

    expect(device.childId).toBeNil()
    let claim = try await Claim.find(code: fixedCode, in: self.db)
    expect(claim?.intent).toEqual(.blockerConnect)
    expect(claim?.deviceId).toEqual(device.id)
    let install = try await device.blockerInstall(in: self.db)
    expect(install.appVersion).toEqual("1.0.0")

    // the connect claim must NOT create a supervision row
    let supervision = try await device.supervision(in: self.db)
    expect(supervision).toBeNil()
  }

  func testIdempotency_reusesExistingValidCode() async throws {
    let deviceId = UUID()
    let fixedCode = uniqueClaimCode()
    let input = CreateBlockerClaimCode.Input(
      deviceId: deviceId,
      modelIdentifier: "iPhone18,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
    )

    let first = try await withDependencies {
      $0.verificationCode = .init(generate: { fixedCode })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateBlockerClaimCode.resolve(with: input, in: .mock)
    }

    let second = try await withDependencies {
      $0.verificationCode = .init(generate: { uniqueClaimCode() })
      $0.date = .constant(.reference)
    } operation: {
      try await CreateBlockerClaimCode.resolve(with: input, in: .mock)
    }

    expect(second.code).toEqual(first.code)
    expect(second.expiresAt).toEqual(first.expiresAt)

    let count = try await IOSDevice.query()
      .where(.id == deviceId)
      .count(in: self.db)
    expect(count).toEqual(1)
  }
}
