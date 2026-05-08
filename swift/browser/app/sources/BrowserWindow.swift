import AppKit
import WebKit

@MainActor
final class BrowserWindow {
  private var window: NSWindow?
  private var webView: WKWebView?

  func show(initialURL: URL?) {
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
      let webView = WKWebView(frame: .zero)
      window.contentView = webView
      self.webView = webView
      self.window = window
    }
    if let url = initialURL {
      self.webView?.load(URLRequest(url: url))
    }
    NSApp.activate(ignoringOtherApps: true)
    self.window?.makeKeyAndOrderFront(nil)
  }
}
