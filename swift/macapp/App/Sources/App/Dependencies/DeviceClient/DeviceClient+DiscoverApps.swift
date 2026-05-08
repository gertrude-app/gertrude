import AppKit
import Foundation
import os.log

struct DiscoveredApp: Equatable, Sendable, Codable {
  var name: String
  var bundleId: String
  var iconPath: String
  var category: String?
  var appVersion: String? = nil
}

@Sendable func getInstalledApps() async -> [DiscoveredApp] {
  let browserNames = Set(hardcodedNames)
  let fm = FileManager.default
  let appDirs = ["/Applications", "/System/Applications", NSHomeDirectory() + "/Applications"]

  let iconDir = NSTemporaryDirectory() + "gertrude-app-icons"
  try? fm.createDirectory(atPath: iconDir, withIntermediateDirectories: true)

  var apps: [DiscoveredApp] = []
  var seenBundleIds = Set<String>()

  for appDir in appDirs {
    guard let contents = try? fm.contentsOfDirectory(atPath: appDir) else {
      os_log("[G•] APP discoverApps: failed to list %{public}s", appDir)
      continue
    }

    var appPaths: [(dir: String, item: String)] = []
    for item in contents {
      if item.hasSuffix(".app") {
        appPaths.append((appDir, item))
      } else {
        let subdir = "\(appDir)/\(item)"
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: subdir, isDirectory: &isDir), isDir.boolValue,
           let subcontents = try? fm.contentsOfDirectory(atPath: subdir) {
          for subitem in subcontents where subitem.hasSuffix(".app") {
            appPaths.append((subdir, subitem))
          }
        }
      }
    }

    os_log("[G•] APP discoverApps: %{public}s has %d .app items", appDir, appPaths.count)

    for (dir, item) in appPaths {
      let path = "\(dir)/\(item)"

      guard let bundle = Bundle(path: path),
            let bundleId = bundle.bundleIdentifier else {
        os_log("[G•] APP discoverApps: no bundle/id for %{public}s", item)
        continue
      }

      if bundleId.contains("com.netrivet.gertrude") { continue }
      guard seenBundleIds.insert(bundleId).inserted else { continue }

      let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? item.replacingOccurrences(of: ".app", with: "")

      if browserNames.contains(name) { continue }

      if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) == nil {
        os_log("[G•] APP discoverApps: urlForApp nil for %{public}s", bundleId)
        continue
      }

      let iconFilePath = "\(iconDir)/\(bundleId).png"

      if !fm.fileExists(atPath: iconFilePath) {
        let icon = NSWorkspace.shared.icon(forFile: path)
        let size = NSSize(width: 128, height: 128)
        let resized = NSImage(size: size)
        resized.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: size))
        resized.unlockFocus()

        guard let tiff = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
          os_log("[G•] APP discoverApps: icon render failed for %{public}s", bundleId)
          continue
        }

        fm.createFile(atPath: iconFilePath, contents: png)
      }

      let category = bundle.object(
        forInfoDictionaryKey: "LSApplicationCategoryType",
      ) as? String

      apps.append(DiscoveredApp(
        name: name,
        bundleId: bundleId,
        iconPath: iconFilePath,
        category: category?.replacingOccurrences(of: "public.app-category.", with: ""),
        appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
      ))
    }
  }

  os_log("[G•] APP discoverApps: returning %d apps", apps.count)
  apps.sort { $0.name.lowercased() < $1.name.lowercased() }
  return apps
}
