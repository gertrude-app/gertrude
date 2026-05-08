import AppKit

@MainActor
final class BrowserWindow {
  private var window: NSWindow?

  func show() {
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
      window.contentView = self.makePlaceholderView()
      self.window = window
    }
    NSApp.activate(ignoringOtherApps: true)
    self.window?.makeKeyAndOrderFront(nil)
  }

  private func makePlaceholderView() -> NSView {
    let label = NSTextField(labelWithString: "Gertie\n\nbrowser placeholder window")
    label.alignment = .center
    label.font = .systemFont(ofSize: 24, weight: .semibold)
    label.lineBreakMode = .byWordWrapping
    label.maximumNumberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    let container = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])
    return container
  }
}
