import AppKit
import Dependencies
import Gertie
import MacAppRoute

@Sendable func quitAllBrowsers(_ browsers: [BrowserMatch]) async {
  await quitBrowsers(browsers, excludeSafari: false)
}

@Sendable func quitAllNonSafariBrowsers(_ browsers: [BrowserMatch]) async {
  await quitBrowsers(browsers, excludeSafari: true)
}

func isNonSafariBrowser(_ app: RunningApp, _ browsers: [BrowserMatch]) -> Bool {
  if app.bundleId == "com.apple.Safari" { return false }
  if app.name == "Safari" { return false }
  let names = Set(browsers.compactMap(\.name) + hardcodedNames)
  let bundleIds = Set(browsers.compactMap(\.bundleId))
  if bundleIds.contains(app.bundleId) { return true }
  if let name = app.name, names.contains(name) { return true }
  return false
}

@Sendable private func quitBrowsers(_ browsers: [BrowserMatch], excludeSafari: Bool) async {
  @Dependency(\.mainQueue) var mainQueue
  let names = Set(browsers.compactMap(\.name) + hardcodedNames)
  let bundleIds = Set(browsers.compactMap(\.bundleId))
  var newBrowsers: ReportBrowsers.Input = []

  for app in NSWorkspace.shared.runningApplications {
    if excludeSafari {
      if app.bundleIdentifier == "com.apple.Safari" { continue }
      if app.localizedName == "Safari" { continue }
    }
    if let bundleId = app.bundleIdentifier {
      if bundleIds.contains(bundleId) {
        await terminate(app: app, on: mainQueue)
        continue
      }
    }
    if let appName = app.localizedName {
      if names.contains(appName) {
        app.bundleIdentifier.map { newBrowsers.append(.init(name: appName, bundleId: $0)) }
        await terminate(app: app, on: mainQueue)
      }
    }
  }

  if !newBrowsers.isEmpty {
    @Dependency(\.api) var api
    try? await api.reportBrowsers(newBrowsers)
  }
}

func terminate(
  app: NSRunningApplication,
  retryDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(3),
  on scheduler: AnySchedulerOf<DispatchQueue>,
) async {
  #if DEBUG
    print("* (DEBUG) skipping terminating app: `\(app.localizedName ?? "")`")
  #else
    app.forceTerminate()
    // checking termination status and "re"-terminating works around
    // loophole where an "unsaved changes" browser alert prevents termination
    try? await scheduler.sleep(for: retryDelay)
    if !app.isTerminated {
      await terminate(app: app, on: scheduler)
    }
  #endif
}

// safeguard, in case we get nothing from api, at least kill all these
private let hardcodedNames = [
  "Arc",
  "Brave Browser",
  "Brave Browser Beta",
  "Brave Browser Nightly",
  "ChatGPT Atlas",
  "Comet",
  "Dia",
  "Safari",
  "Google Chrome",
  "Google Chrome Beta",
  "Google Chrome Canary",
  "Google Chrome for Testing",
  "Firefox",
  "Firefox Nightly",
  "Firefox Developer Edition",
  "Chromium",
  "Opera",
  "Microsoft Edge",
  "Sizzy",
  "Vivaldi",
  "LockDown Browser",
  "Puffin",
  "Avast",
  "Avast Secure Browser",
]
