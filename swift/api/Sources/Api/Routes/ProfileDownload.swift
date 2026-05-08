import Dependencies
import DuetSQL
import GertieIOS
import Vapor

enum ProfileDownloadRoute {
  @Sendable static func handler(_ req: Request) async throws -> Response {
    guard let deviceIdString = req.parameters.get("deviceId"),
          let uuid = UUID(uuidString: deviceIdString) else {
      logIOSUnusual("42d8c06b", "invalid device id: `\(req.parameters.get("deviceId") ?? "nil")`")
      throw Abort(.badRequest)
    }

    let deviceId = IOSDevice.Id(uuid)
    guard let device = try? await req.context.db.find(deviceId) else {
      logIOSUnusual("5ec451f9", "device not found: \(deviceId.lowercased)")
      throw Abort(.notFound)
    }

    guard let supervision = try await device.supervision(in: req.context.db),
          supervision.supervised else {
      logIOSUnusual("2b761bf2", "device not supervised: \(deviceId.lowercased)")
      throw Abort(.notFound)
    }

    if let child = try await device.child(in: req.context.db) {
      let parent = try await child.parent(in: req.context.db)
      let billing = try await parent.parentBilling(in: req.context.db)
      if !billing.allowsSupervision {
        let parentLink = AdminLink().slack(to: .parent(parent.id), text: parent.email.rawValue)
        Task {
          await get(dependency: \.slack)
            .internal(
              .info,
              "*iOS supervision:* profile download blocked (no subscription), \(parentLink)",
            )
        }
        return Response(
          status: .paymentRequired,
          headers: ["Content-Type": "text/html; charset=utf-8"],
          body: .init(string: SUBSCRIPTION_REQUIRED_HTML),
        )
      }
    }

    let install = try await device.install(in: req.context.db)
    let xml = generateProfileXml(for: device, install: install)
    let signer = with(dependency: \.profileSigner)
    let signedBytes = try signer.sign(Array(xml.utf8))

    return Response(
      headers: [
        "Content-Type": "application/x-apple-aspen-config",
        "Content-Disposition": "attachment; filename=\"Gertrude.mobileconfig\"",
      ],
      body: .init(data: Data(signedBytes)),
    )
  }
}

// @see https://developer.apple.com/documentation/devicemanagement/toplevel
// @see https://developer.apple.com/documentation/devicemanagement/webcontentfilter
// `DenyListURLS` is interesting, can specify 500 URLs, could put top 500 porn sites there...
// `SafariHistoryRetentionEnabled`, also cool, kills private mode, and history clearing
func generateProfileXml(for device: IOSDevice, install: BlockerApp.Install) -> String {
  var restrictionKeys = """
        <key>allowAppRemoval</key>
        <\(install.allowAppRemoval ? "true" : "false")/>

        <key>allowEraseContentAndSettings</key>
        <\(install.allowEraseContentAndSettings ? "true" : "false")/>
  """
  // special temporary customer workaround
  if device.id.lowercased == "ed25c68a-2dba-4854-b3bd-efe0d8523e6f" {
    restrictionKeys += """

          <key>allowSafari</key>
          <false/>

          <key>allowAppInstallation</key>
          <false/>
    """
  }
  return """
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
      <string>\(device.id.lowercased)</string>

      <key>PayloadVersion</key>
      <integer>1</integer>

      <key>PayloadDescription</key>
      <string>This profile allows the device to be securely managed by a Gertrude account.</string>

      <key>PayloadRemovalDisallowed</key>
      <\(install.isProfileLocked ? "true" : "false")/>

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

  \(restrictionKeys)
        </dict>
      </array>
    </dict>
  </plist>
  """.trimmingCharacters(in: .whitespacesAndNewlines)
}

private let SUBSCRIPTION_REQUIRED_HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Subscription Required</title>
  <style>
    body {
      font-family: -apple-system, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background: #f5f3ff;
      padding: 24px;
      box-sizing: border-box;
    }
    .card {
      background: white;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      box-shadow: 0 4px 24px rgba(109, 40, 217, 0.1);
    }
    h1 { color: #5b21b6; font-size: 22px; margin: 0 0 12px; }
    p { color: #4b5563; font-size: 15px; line-height: 1.5; margin: 0; }
    .url { color: #7c3aed; white-space: nowrap; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Subscription Required</h1>
    <p>Gertrude supervision requires a paid subscription ($10/year). Subscribe at <span class="url">https://parents.gertrude.app</span> and then try again.</p>
  </div>
</body>
</html>
"""
