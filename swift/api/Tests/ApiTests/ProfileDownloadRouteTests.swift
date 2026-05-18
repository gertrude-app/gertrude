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
    let device = try await self.db.create(IOSDevice.mock)
    try await self.db.create(BlockerApp.Install.mock { $0.deviceId = device.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
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
    let device = try await self.db.create(IOSDevice.mock)
    var install = BlockerApp.Install.mock { $0.deviceId = device.id }
    install.isProfileLocked = false
    try await self.db.create(install)
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
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
    let device = try await self.db.create(IOSDevice.mock)

    try await app.test(
      .GET,
      "ios-profile/\(device.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.notFound)
      },
    )
  }

  func testSupervisedDevice_blockedWithoutEligiblePlan() async throws {
    // standalone trial: identity-only, no live subscription → no supervision allowed
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference,
    ))
    let child = try await self.db.create(Child(parentId: parent.id, name: "Test Child"))
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
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

    let xml = generateProfileXml(for: .mock, install: .mock)
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
