import AppKit

final class BrowserWindowController: NSWindowController {
  private let webViewController: WebViewController

  init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false,
    )
    window.title = "BrowserSpike"
    window.center()
    window.setFrameAutosaveName("BrowserSpikeMainWindow")

    let controller = WebViewController()
    self.webViewController = controller

    super.init(window: window)
    window.contentViewController = controller
    window.makeFirstResponder(controller.omnibarField)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

  func load(url: URL) {
    self.webViewController.load(urlString: url.absoluteString)
  }
}
