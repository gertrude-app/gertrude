import Crypto
import Dependencies
import DuetSQL
import Foundation
@_spi(CMS) import X509
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class ProfileDownloadRouteTests: ApiTestCase, @unchecked Sendable {
  func testSupervisedDevice_returnsProfileWithCorrectHeaders() async throws {
    let device = try await self.db.create(IOSApp.Device.mock)
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
    ))

    try await app.test(
      .GET,
      "ios-profile/\(device.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.ok)
        expect(res.headers.first(name: .contentType))
          .toEqual("application/x-apple-aspen-config")
        expect(res.headers.first(name: .contentDisposition))
          .toEqual("attachment; filename=\"Gertrude.mobileconfig\"")
        expect(res.body.string).toContain("<!DOCTYPE plist")
        expect(res.body.string).toContain(device.id.lowercased)
        expect(res.body.string).toContain("PayloadRemovalDisallowed")
        expect(res.body.string).toContain("RemovalDisallowed</key>\n    <true/>")
      },
    )
  }

  func testUnlockedDevice_servesRemovableProfile() async throws {
    var mock = IOSApp.Device.mock
    mock.isProfileLocked = false
    let device = try await self.db.create(mock)
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
    ))

    try await app.test(
      .GET,
      "ios-profile/\(device.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.body.string).toContain("RemovalDisallowed</key>\n    <false/>")
      },
    )
  }

  func testNonSupervisedDevice_returns404() async throws {
    let device = try await self.db.create(IOSApp.Device.mock)

    try await app.test(
      .GET,
      "ios-profile/\(device.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.notFound)
      },
    )
  }

  func testSupervisedDevice_blockedWithoutEligiblePlan() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .full
      $1.billingStatus = .trialing
      $1.trialStartedAt = .reference
      $1.statusExpiresAt = .reference + .days(18)
    }
    let child = try await self.db.create(Child(parentId: parent.id, name: "Test Child"))
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
    ))

    try await app.test(
      .GET,
      "ios-profile/\(device.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.paymentRequired)
        expect(res.headers.first(name: .contentType) ?? "").toContain("text/html")
        expect(res.body.string).toContain("Subscription Required")
      },
    )
  }

  func testCmsSigningRoundTrip() throws {
    let key = P256.Signing.PrivateKey()
    let name = try DistinguishedName { CommonName("Test Profile Signer") }
    let now = Date()
    let cert = try Certificate(
      version: .v3,
      serialNumber: .init(),
      publicKey: .init(key.publicKey),
      notValidBefore: now.addingTimeInterval(-3600),
      notValidAfter: now.addingTimeInterval(3600),
      issuer: name,
      subject: name,
      signatureAlgorithm: .ecdsaWithSHA256,
      extensions: Certificate.Extensions {},
      issuerPrivateKey: .init(key),
    )

    let xml = generateProfileXml(for: .mock)
    let xmlBytes = Array(xml.utf8)

    let signedBytes = try CMS.sign(
      xmlBytes,
      signatureAlgorithm: .ecdsaWithSHA256,
      certificate: cert,
      privateKey: .init(key),
      detached: false,
    )

    XCTAssertFalse(signedBytes.isEmpty)
    XCTAssertNotEqual(signedBytes, xmlBytes)
    XCTAssertTrue(signedBytes.count > xmlBytes.count)
  }
}
