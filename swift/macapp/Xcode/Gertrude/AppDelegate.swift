import App
import AppKit
import Cocoa
import Core
import Gertie
import LiveApiClient
import LiveAppClient
import LiveFilterExtensionClient
import LiveFilterXPCClient
import LiveUpdaterClient
import LiveWebSocketClient

class AppDelegate: NSViewController, NSApplicationDelegate, NSWindowDelegate {
  let app = App()
  private var runningAppsObservation: NSKeyValueObservation?
  private var siriUITracker = SiriUITracker()

  func applicationDidFinishLaunching(_ notification: Notification) {
    self.app.send(.didFinishLaunching)

    // NB: wake/sleep notifications are NOT posted to NotificationCenter.default
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(AppDelegate.receiveSleep(_:)),
      name: NSWorkspace.willSleepNotification,
      object: nil,
    )

    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(AppDelegate.receiveWakeup(_:)),
      name: NSWorkspace.didWakeNotification,
      object: nil,
    )

    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didLaunchApplicationNotification,
      object: nil,
      queue: nil,
    ) { [weak self] notification in
      if let app = notification
        .userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
        self?.app.send(.appLaunched(pid: app.processIdentifier))
      }
    }

    self.runningAppsObservation = NSWorkspace.shared.observe(
      \.runningApplications,
      options: [.initial, .new],
    ) { [weak self] workspace, _ in
      let apps = workspace.runningApplications.filter {
        $0.bundleIdentifier == SiriBundleId.app.rawValue
          || $0.bundleIdentifier == SiriBundleId.uiService.rawValue
      }.compactMap(\.runningApp)
      DispatchQueue.main.async { [weak self] in
        guard let self, let host = self.siriUITracker.newlyPresentedHost(in: apps) else { return }
        self.app.send(.siriUIPresented(pid: host.pid))
      }
    }

    // NB: clock/tz changes are NOT posted to NSWorkspace.shared.notificationCenter
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSSystemClockDidChange,
      object: nil,
      queue: nil,
    ) { [weak self] _ in
      self?.app.send(.systemClockOrTimeZoneChanged)
    }

    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSSystemTimeZoneDidChange,
      object: nil,
      queue: nil,
    ) { [weak self] _ in
      self?.app.send(.systemClockOrTimeZoneChanged)
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    self.runningAppsObservation = nil
    self.app.send(.willTerminate)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  @objc func receiveSleep(_ notification: Notification) {
    self.app.send(.willSleep)
  }

  @objc func receiveWakeup(_ notification: Notification) {
    self.app.send(.didWake)
  }
}
