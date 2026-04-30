import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  var windowController: BrowserWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    self.installMainMenu()
    self.ensureWindow()
    NSApp.activate(ignoringOtherApps: true)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    print("[app] application(_:open:) urls=\(urls.map(\.absoluteString))")
    self.ensureWindow()
    if let url = urls.first {
      self.windowController?.load(url: url)
    }
    NSApp.activate(ignoringOtherApps: true)
  }

  private func ensureWindow() {
    if self.windowController == nil {
      let controller = BrowserWindowController()
      controller.showWindow(nil)
      self.windowController = controller
    }
  }

  private func installMainMenu() {
    let mainMenu = NSMenu()

    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    let appMenu = NSMenu(title: "BrowserSpike")
    appMenu.addItem(
      withTitle: "Quit BrowserSpike",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q",
    )
    appMenuItem.submenu = appMenu

    let editMenuItem = NSMenuItem()
    mainMenu.addItem(editMenuItem)
    let editMenu = NSMenu(title: "Edit")
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(
      withTitle: "Select All",
      action: #selector(NSText.selectAll(_:)),
      keyEquivalent: "a",
    )
    editMenuItem.submenu = editMenu

    NSApp.mainMenu = mainMenu
  }
}
