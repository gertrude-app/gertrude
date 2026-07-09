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
    var settings = BlockerApp.ProfileSettings.mock { $0.deviceId = device.id }
    settings.isProfileLocked = false
    try await self.db.create(settings)
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

  func testProfileSettingsJsonColumnsRoundTrip() async throws {
    let device = try await self.db.create(IOSDevice.mock)
    var settings = BlockerApp.ProfileSettings.mock { $0.deviceId = device.id }
    settings.whitelistedAppBundleIds = ["com.apple.mobilesafari", "com.acme.app"]
    settings.webAllowList = [.init(url: "https://example.com", title: "Example")]
    try await self.db.create(settings)

    let retrieved = try await BlockerApp.ProfileSettings.query()
      .where(.deviceId == device.id)
      .first(in: self.db)

    expect(retrieved.whitelistedAppBundleIds)
      .toEqual(["com.apple.mobilesafari", "com.acme.app"])
    expect(retrieved.webAllowList)
      .toEqual([.init(url: "https://example.com", title: "Example")])

    let ensured = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(ensured.id).toEqual(settings.id) // ensure finds, never clobbers existing
  }

  // golden master: default config must produce EXACTLY this xml, byte for byte,
  // preserved through the profile_settings refactor and the absent-vs-empty
  // semantics of new nullable config (no config -> no new keys emitted)
  func testGoldenProfileXmlDefaultConfig() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let xml = generateProfileXml(for: device, settings: .mock { $0.deviceId = device.id })
    expect(xml).toEqual("""
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>PayloadDisplayName</key>
        <string>Gertrude App Helper</string>

        <key>PayloadIdentifier</key>
        <string>app.gertrude.ios-profile</string>

        <key>PayloadType</key>
        <string>Configuration</string>

        <key>PayloadUUID</key>
        <string>aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000</string>

        <key>PayloadVersion</key>
        <integer>1</integer>

        <key>PayloadDescription</key>
        <string>This profile allows the device to be securely managed by a Gertrude account.</string>

        <key>PayloadRemovalDisallowed</key>
        <true/>

        <key>PayloadContent</key>
        <array>
          <dict>
            <key>PayloadType</key>
            <string>com.apple.webcontent-filter</string>

            <key>FilterType</key>
            <string>Plugin</string>

            <key>PayloadDescription</key>
            <string>Configures content filtering settings</string>

            <key>PayloadVersion</key>
            <integer>1</integer>

            <key>PluginBundleID</key>
            <string>com.netrivet.gertrude-ios.app</string>

            <key>UserDefinedName</key>
            <string>Gertrude</string>

            <key>PayloadIdentifier</key>
            <string>com.apple.webcontent-filter.b04adbcd-327c-4384-ba3e-28e2191b3fbf</string>

            <key>PayloadUUID</key>
            <string>b04adbcd-327c-4384-ba3e-28e2191b3fbf</string>

            <key>FilterSockets</key>
            <true/>

            <key>FilterBrowsers</key>
            <true/>
          </dict>

          <dict>
            <key>PayloadType</key>
            <string>com.apple.applicationaccess</string>

            <key>PayloadIdentifier</key>
            <string>app.gertrude.restrictions.ba37d4c5-f939-47b8-9e89-d8d7e1fc1592</string>

            <key>PayloadUUID</key>
            <string>ba37d4c5-f939-47b8-9e89-d8d7e1fc1592</string>

            <key>PayloadVersion</key>
            <integer>1</integer>

          <key>allowAppRemoval</key>
          <false/>

          <key>allowEraseContentAndSettings</key>
          <false/>

          <key>allowAppInstallation</key>
          <true/>
          </dict>
        </array>
      </dict>
    </plist>
    """)
  }

  func testGoldenProfileXmlSafariWorkaroundDevice() {
    let device = IOSDevice.mock {
      $0
        .id =
        .init(UUID(
          uuidString: "ed25c68a-2dba-4854-b3bd-efe0d8523e6f",
        )!) // hardcoded workaround device
    }
    var settings = BlockerApp.ProfileSettings.mock { $0.deviceId = device.id }
    settings.allowAppInstallation = false // matches prod row for this device
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml).toEqual("""
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>PayloadDisplayName</key>
        <string>Gertrude App Helper</string>

        <key>PayloadIdentifier</key>
        <string>app.gertrude.ios-profile</string>

        <key>PayloadType</key>
        <string>Configuration</string>

        <key>PayloadUUID</key>
        <string>ed25c68a-2dba-4854-b3bd-efe0d8523e6f</string>

        <key>PayloadVersion</key>
        <integer>1</integer>

        <key>PayloadDescription</key>
        <string>This profile allows the device to be securely managed by a Gertrude account.</string>

        <key>PayloadRemovalDisallowed</key>
        <true/>

        <key>PayloadContent</key>
        <array>
          <dict>
            <key>PayloadType</key>
            <string>com.apple.webcontent-filter</string>

            <key>FilterType</key>
            <string>Plugin</string>

            <key>PayloadDescription</key>
            <string>Configures content filtering settings</string>

            <key>PayloadVersion</key>
            <integer>1</integer>

            <key>PluginBundleID</key>
            <string>com.netrivet.gertrude-ios.app</string>

            <key>UserDefinedName</key>
            <string>Gertrude</string>

            <key>PayloadIdentifier</key>
            <string>com.apple.webcontent-filter.b04adbcd-327c-4384-ba3e-28e2191b3fbf</string>

            <key>PayloadUUID</key>
            <string>b04adbcd-327c-4384-ba3e-28e2191b3fbf</string>

            <key>FilterSockets</key>
            <true/>

            <key>FilterBrowsers</key>
            <true/>
          </dict>

          <dict>
            <key>PayloadType</key>
            <string>com.apple.applicationaccess</string>

            <key>PayloadIdentifier</key>
            <string>app.gertrude.restrictions.ba37d4c5-f939-47b8-9e89-d8d7e1fc1592</string>

            <key>PayloadUUID</key>
            <string>ba37d4c5-f939-47b8-9e89-d8d7e1fc1592</string>

            <key>PayloadVersion</key>
            <integer>1</integer>

          <key>allowAppRemoval</key>
          <false/>

          <key>allowEraseContentAndSettings</key>
          <false/>

          <key>allowAppInstallation</key>
          <false/>
          <key>allowSafari</key>
          <false/>
          </dict>
        </array>
      </dict>
    </plist>
    """)
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

    let xml = generateProfileXml(for: .mock, settings: .mock)
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
