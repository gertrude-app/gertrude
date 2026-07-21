import AppKit
import SwiftUI

@MainActor
final class BrowserWindow {
  private var window: NSWindow?

  func show(rootView: some View) {
    if self.window == nil {
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false,
      )
      window.minSize = NSSize(width: 600, height: 400)
      window.title = "Gertie"
      window.center()
      window.isReleasedWhenClosed = false
      window.contentView = NSHostingView(rootView: rootView)
      self.window = window
    }
    NSApp.activate(ignoringOtherApps: true)
    self.window?.makeKeyAndOrderFront(nil)
  }
}
