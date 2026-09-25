import DuetSQL
import GertieBlocker
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
      let account = try await parent.billingAccountSnapshot(
        in: req.context.db,
        at: get(dependency: \.date.now),
      )
      if !account.can(.superviseIosDevice) {
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
      if let limit = account.supervisedIOSDeviceLimit,
         try await parent.supervisedIOSDevices(in: req.context.db).count > limit {
        let parentLink = AdminLink().slack(to: .parent(parent.id), text: parent.email.rawValue)
        Task {
          await get(dependency: \.slack)
            .internal(
              .info,
              "*iOS supervision:* profile download blocked (over device limit), \(parentLink)",
            )
        }
        return Response(
          status: .paymentRequired,
          headers: ["Content-Type": "text/html; charset=utf-8"],
          body: .init(string: DEVICE_LIMIT_REACHED_HTML),
        )
      }
    }

    let settings = try await BlockerApp.ProfileSettings.ensure(
      for: device.id,
      in: req.context.db,
    )
    let xml = generateProfileXml(for: device, settings: settings)
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
func generateProfileXml(
  for device: IOSDevice,
  settings: BlockerApp.ProfileSettings,
) -> String {
  var restrictionKeys = """
        <key>allowAppRemoval</key>
        <\(settings.allowAppRemoval ? "true" : "false")/>

        <key>allowEraseContentAndSettings</key>
        <\(settings.allowEraseContentAndSettings ? "true" : "false")/>

        <key>allowAppInstallation</key>
        <\(settings.allowAppInstallation ? "true" : "false")/>
  """
  if let bundleIds = settings.whitelistedAppBundleIds {
    restrictionKeys += "\n\n      <key>whitelistedAppBundleIDs</key>\n      "
    restrictionKeys += plistStringArray(
      bundleIds.contains(GERTRUDE_APP_BUNDLE_ID)
        ? bundleIds
        : bundleIds + [GERTRUDE_APP_BUNDLE_ID],
      indent: 6,
    )
  }
  let extendedBoolKeys: [(String, Bool?)] = [
    ("allowiTunes", settings.allowItunes),
    ("allowMusicService", settings.allowMusicService),
    ("allowRadioService", settings.allowRadioService),
    ("allowNews", settings.allowNews),
    ("allowBookstore", settings.allowBookstore),
    ("allowExplicitContent", settings.allowExplicitContent),
    ("allowSafari", settings.allowSafari),
    ("allowSpotlightInternetResults", settings.allowSpotlightInternetResults),
    ("allowDefinitionLookup", settings.allowDefinitionLookup),
    ("allowAutomaticAppDownloads", settings.allowAutomaticAppDownloads),
    ("allowAppClips", settings.allowAppClips),
    ("allowSystemAppRemoval", settings.allowSystemAppRemoval),
    ("allowAssistant", settings.allowAssistant),
    ("allowGameCenter", settings.allowGameCenter),
    ("forceDelayedSoftwareUpdates", settings.forceDelayedSoftwareUpdates),
    ("forceAutomaticDateAndTime", settings.forceAutomaticDateAndTime),
  ]
  for (key, value) in extendedBoolKeys {
    restrictionKeys += plistBoolKey(key, value)
  }
  let extendedIntKeys: [(String, Int?)] = [
    ("ratingMovies", settings.ratingMovies),
    ("ratingTVShows", settings.ratingTvShows),
    ("enforcedSoftwareUpdateDelay", settings.enforcedSoftwareUpdateDelay),
  ]
  for (key, value) in extendedIntKeys {
    restrictionKeys += plistIntKey(key, value)
  }
  if settings.ratingMovies != nil || settings.ratingTvShows != nil {
    restrictionKeys += "\n\n      <key>ratingRegion</key>\n      <string>us</string>"
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
      <\(settings.isProfileLocked ? "true" : "false")/>

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
  \(settings.webAllowList.map(builtInWebFilterXml) ?? "")
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

private func builtInWebFilterXml(
  _ bookmarks: [BlockerApp.ProfileSettings.Bookmark],
) -> String {
  let bookmarkDicts = bookmarks.map { bookmark in
    """
              <dict>
                <key>Title</key>
                <string>\(xmlEscaped(bookmark.title))</string>

                <key>URL</key>
                <string>\(xmlEscaped(bookmark.url))</string>
              </dict>
    """
  }.joined(separator: "\n")
  let array = bookmarks.isEmpty ? "<array/>" : "<array>\n\(bookmarkDicts)\n        </array>"
  return """

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
          \(array)
        </dict>

  """
}

private let GERTRUDE_APP_BUNDLE_ID = "com.netrivet.gertrude-ios.app"

private func plistStringArray(_ strings: [String], indent: Int) -> String {
  let pad = String(repeating: " ", count: indent)
  guard !strings.isEmpty else { return "<array/>" }
  let entries = strings
    .map { "\(pad)  <string>\(xmlEscaped($0))</string>" }
    .joined(separator: "\n")
  return "<array>\n\(entries)\n\(pad)</array>"
}

private func plistBoolKey(_ key: String, _ value: Bool?) -> String {
  guard let value else { return "" }
  return "\n\n      <key>\(key)</key>\n      <\(value ? "true" : "false")/>"
}

private func plistIntKey(_ key: String, _ value: Int?) -> String {
  guard let value else { return "" }
  return "\n\n      <key>\(key)</key>\n      <integer>\(value)</integer>"
}

private func xmlEscaped(_ string: String) -> String {
  string
    .replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
}

private let SUBSCRIPTION_REQUIRED_HTML = noticePageHtml(
  title: "Subscription Required",
  paragraphs: [
    """
    Gertrude supervision requires a paid subscription ($10/year). Subscribe at \
    <span class="url">https://parents.gertrude.app</span> and then try again.
    """,
  ],
)

private let DEVICE_LIMIT_REACHED_HTML = noticePageHtml(
  title: "Device Limit Reached",
  paragraphs: [
    """
    This account has supervised more iPhones and iPads than Gertrude allows. \
    Gertrude is built for parents and accountability partners helping kids and friends.
    """,
    """
    If that describes you and you need more devices, get in touch at \
    <span class="url">https://gertrude.app/contact</span> and we'll sort it out with you.
    """,
  ],
)

private func noticePageHtml(title: String, paragraphs: [String]) -> String {
  let body = paragraphs.map { "    <p>\($0)</p>" }.joined(separator: "\n")
  return """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>\(title)</title>
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
      p { color: #4b5563; font-size: 15px; line-height: 1.5; margin: 0 0 12px; }
      p:last-child { margin-bottom: 0; }
      .url { color: #7c3aed; white-space: nowrap; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>\(title)</h1>
  \(body)
    </div>
  </body>
  </html>
  """
}
