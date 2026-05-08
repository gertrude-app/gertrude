import AppKit
import BrowserApp

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  let app = App()
  let browserWindow = BrowserWindow()

  func applicationDidFinishLaunching(_ notification: Notification) {
    self.app.send(.didFinishLaunching)
    self.browserWindow.show(initialURL: self.app.currentTabURL)
  }
}
