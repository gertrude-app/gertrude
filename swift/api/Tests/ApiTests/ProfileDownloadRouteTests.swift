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

  func testSupervisedDeviceCountTalliesPhonesNotRows() async throws {
    let child = try await self.child()
    // "a" re-supervised twice is one phone; null udids can't be deduped, so count singly
    try await self.supervise(child.id, udids: ["a", "a", "b", nil, nil])
    let abandoned = try await self.db.create(IOSDevice.mock { $0.childId = child.id })
    try await self.db.create(BlockerApp.Supervision(deviceId: abandoned.id, udid: "c"))
    let other = try await self.child()
    try await self.supervise(other.id, udids: ["x", "y", "z"])

    let count = try await child.parent.model.supervisedIOSDevices(in: self.db).count

    expect(count).toEqual(4) // a + b + 2 unidentified, not "c" (never finished) or another parent's
  }

  func testAtDeviceLimit_servesProfile() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.id, tier: .light)
    let devices = try await self.supervise(child.id, udids: (1 ... 5).map { "udid-\($0)" })

    try await app.test(
      .GET,
      "ios-profile/\(devices.last!.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.ok)
      },
    )
  }

  func testOverDeviceLimit_blockedWithContactCopy() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.id, tier: .light)
    let devices = try await self.supervise(child.id, udids: (1 ... 6).map { "udid-\($0)" })

    try await app.test(
      .GET,
      "ios-profile/\(devices.last!.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.paymentRequired)
        expect(res.body.string).toContain("Device Limit Reached")
        expect(res.body.string).toContain("gertrude.app/contact")
        // the copy must route to a human, never to a bigger plan
        expect(res.body.string.lowercased().contains("upgrade")).toBeFalse()
        expect(res.body.string.contains("parents.gertrude.app")).toBeFalse()
      },
    )
  }

  func testComplimentaryAccountIsUncapped() async throws {
    let child = try await self.child()
    try await self.db.create(BillingIdentity(parentId: child.parent.id, isComplimentary: true))
    let devices = try await self.supervise(child.id, udids: (1 ... 25).map { "udid-\($0)" })

    try await app.test(
      .GET,
      "ios-profile/\(devices.last!.id.lowercased)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.ok)
      },
    )
  }

  func testProfileSettingsJsonColumnsRoundTrip() async throws {
    let device = try await self.db.create(IOSDevice.mock)
    var settings = BlockerApp.ProfileSettings.mock { $0.deviceId = device.id }
    settings.whitelistedAppBundleIds = ["com.apple.mobilesafari", "com.acme.app"]
    settings.webAllowList = [.init(url: "https://example.com/bob's", title: "Bob's Site")]
    try await self.db.create(settings)

    let retrieved = try await BlockerApp.ProfileSettings.query()
      .where(.deviceId == device.id)
      .first(in: self.db)

    expect(retrieved.whitelistedAppBundleIds)
      .toEqual(["com.apple.mobilesafari", "com.acme.app"])
    expect(retrieved.webAllowList)
      .toEqual([.init(url: "https://example.com/bob's", title: "Bob's Site")])

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

  // golden master: populated whitelist + web allowlist, pinning payload placement,
  // key names/casing from the validated spike, and xml escaping
  func testGoldenProfileXmlFullConfig() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.whitelistedAppBundleIds = ["com.apple.AppStore", "com.culturedcode.ThingsiPhone"]
      $0.webAllowList = [
        .init(url: "https://example.com", title: "Example"),
        .init(url: "https://site.com/a?b=1&c=2", title: "Q&A <site>"), // exercises escaping
      ]
    }
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
            <string>com.apple.webcontent-filter</string>

            <key>FilterType</key>
            <string>BuiltIn</string>

            <key>AutoFilterEnabled</key>
            <false/>

            <key>PayloadDescription</key>
            <string>Configures allowed websites</string>

            <key>PayloadDisplayName</key>
            <string>Gertrude Allowed Websites</string>

            <key>PayloadIdentifier</key>
            <string>app.gertrude.builtin-webfilter.24f0679b-6e8d-44fa-b4ef-e5d2f7a18b13</string>

            <key>PayloadUUID</key>
            <string>24f0679b-6e8d-44fa-b4ef-e5d2f7a18b13</string>

            <key>PayloadVersion</key>
            <integer>1</integer>

            <key>AllowListBookmarks</key>
            <array>
              <dict>
                <key>Title</key>
                <string>Example</string>

                <key>URL</key>
                <string>https://example.com</string>
              </dict>
              <dict>
                <key>Title</key>
                <string>Q&amp;A &lt;site&gt;</string>

                <key>URL</key>
                <string>https://site.com/a?b=1&amp;c=2</string>
              </dict>
            </array>
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

          <key>whitelistedAppBundleIDs</key>
          <array>
            <string>com.apple.AppStore</string>
            <string>com.culturedcode.ThingsiPhone</string>
            <string>com.netrivet.gertrude-ios.app</string>
          </array>
          </dict>
        </array>
      </dict>
    </plist>
    """)
  }

  // empty-but-present lists are maximally restrictive: hide all apps, block whole web
  func testEmptyListsEmitEmptyArrays() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.whitelistedAppBundleIds = []
      $0.webAllowList = []
    }
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml).toContain("<key>AllowListBookmarks</key>\n        <array/>")
    expect(xml).toContain("<key>FilterType</key>\n        <string>BuiltIn</string>")
    expect(xml).toContain("<key>AutoFilterEnabled</key>\n        <false/>")
  }

  // an app whitelist that omits our own app hides the only way to sync a corrected
  // profile, and a locked profile can't be removed -- so we always append ourselves
  func testWhitelistAlwaysIncludesGertrudeApp() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.whitelistedAppBundleIds = ["com.culturedcode.ThingsiPhone"]
    }
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml).toContain("""
    <key>whitelistedAppBundleIDs</key>
          <array>
            <string>com.culturedcode.ThingsiPhone</string>
            <string>com.netrivet.gertrude-ios.app</string>
          </array>
    """)
  }

  func testEmptyWhitelistStillIncludesGertrudeApp() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.whitelistedAppBundleIds = [] // "approve nothing" must still leave us recoverable
    }
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml).toContain("""
    <key>whitelistedAppBundleIDs</key>
          <array>
            <string>com.netrivet.gertrude-ios.app</string>
          </array>
    """)
  }

  func testWhitelistDoesntDuplicateGertrudeApp() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.whitelistedAppBundleIds = ["com.netrivet.gertrude-ios.app", "com.apple.AppStore"]
    }
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml).toContain("""
    <key>whitelistedAppBundleIDs</key>
          <array>
            <string>com.netrivet.gertrude-ios.app</string>
            <string>com.apple.AppStore</string>
          </array>
    """)
  }

  // nil (feature off) must stay absent -- appending would silently hide every other app
  func testNilWhitelistEmitsNoKeyAtAll() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.whitelistedAppBundleIds = nil
    }
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml.contains("whitelistedAppBundleIDs")).toBeFalse()
  }

  func testExtendedRestrictionsEmitWhenSet() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.allowItunes = false
      $0.allowExplicitContent = false
      $0.ratingMovies = 0
      $0.ratingTvShows = 200
      $0.forceDelayedSoftwareUpdates = true
      $0.enforcedSoftwareUpdateDelay = 30
      // allowSafari, allowGameCenter, etc. deliberately left nil
    }
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml).toContain("<key>allowiTunes</key>\n      <false/>") // lowercase-i casing
    expect(xml).toContain("<key>allowExplicitContent</key>\n      <false/>")
    expect(xml)
      .toContain("<key>ratingMovies</key>\n      <integer>0</integer>") // integer, not bool
    expect(xml)
      .toContain("<key>ratingTVShows</key>\n      <integer>200</integer>") // TVShows casing
    expect(xml).toContain("<key>ratingRegion</key>\n      <string>us</string>")
    expect(xml).toContain("<key>forceDelayedSoftwareUpdates</key>\n      <true/>") // true emits too
    expect(xml).toContain("<key>enforcedSoftwareUpdateDelay</key>\n      <integer>30</integer>")
    expect(xml.contains("allowSafari")).toBeFalse() // nil keys omitted entirely
    expect(xml.contains("allowGameCenter")).toBeFalse()
  }

  func testRatingRegionOmittedWithoutRatings() {
    let device = IOSDevice.mock {
      $0.id = .init(UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000")!)
    }
    let settings = BlockerApp.ProfileSettings.mock {
      $0.deviceId = device.id
      $0.allowSafari = false
    }
    let xml = generateProfileXml(for: device, settings: settings)
    expect(xml).toContain("<key>allowSafari</key>\n      <false/>")
    expect(xml.contains("ratingRegion")).toBeFalse()
    expect(xml.contains("ratingMovies")).toBeFalse()
  }

  @discardableResult
  private func supervise(
    _ childId: Child.Id,
    udids: [String?],
  ) async throws -> [IOSDevice] {
    var devices: [IOSDevice] = []
    for udid in udids {
      let device = try await self.db.create(IOSDevice.mock { $0.childId = childId })
      try await self.db.create(BlockerApp.Supervision(
        deviceId: device.id,
        udid: udid,
        supervisedAt: .reference,
      ))
      devices.append(device)
    }
    return devices
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
