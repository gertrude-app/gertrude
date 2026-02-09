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

    let deviceId = IOSApp.Device.Id(uuid)
    guard let device = try? await req.context.db.find(deviceId) else {
      logIOSUnusual("5ec451f9", "device not found: \(deviceId.lowercased)")
      throw Abort(.notFound)
    }

    guard let supervision = try await device.supervision(in: req.context.db),
          supervision.supervised else {
      logIOSUnusual("2b761bf2", "device not supervised: \(deviceId.lowercased)")
      throw Abort(.notFound)
    }

    return Response(
      headers: [
        "Content-Type": "application/x-apple-aspen-config",
        "Content-Disposition": "attachment; filename=\"Gertrude.mobileconfig\"",
      ],
      body: .init(string: generateProfileXml(for: device)),
    )
  }
}

// @see https://developer.apple.com/documentation/devicemanagement/toplevel
// @see https://developer.apple.com/documentation/devicemanagement/webcontentfilter
// `DenyListURLS` is interesting, can specify 500 URLs, could put top 500 porn sites there...
// `SafariHistoryRetentionEnabled`, also cool, kills private mode, and history clearing
func generateProfileXml(for device: IOSApp.Device) -> String {
  """
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
      <\(device.isProfileLocked ? "true" : "false")/>

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
      </array>
    </dict>
  </plist>
  """.trimmingCharacters(in: .whitespacesAndNewlines)
}
