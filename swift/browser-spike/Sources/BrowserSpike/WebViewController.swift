import AppKit
import WebKit

final class WebViewController: NSViewController, NSTextFieldDelegate {
  let webView: WKWebView
  let omnibarField: NSTextField
  private let backButton: NSButton
  private let forwardButton: NSButton
  private let reloadButton: NSButton
  private var titleObservation: NSKeyValueObservation?
  private var urlObservation: NSKeyValueObservation?
  private var canGoBackObservation: NSKeyValueObservation?
  private var canGoForwardObservation: NSKeyValueObservation?

  init() {
    let config = WKWebViewConfiguration()
    config.websiteDataStore = .nonPersistent()
    self.webView = WKWebView(frame: .zero, configuration: config)
    self.webView.translatesAutoresizingMaskIntoConstraints = false
    self.webView.allowsBackForwardNavigationGestures = true
    if #available(macOS 13.3, *) {
      self.webView.isInspectable = true
    }

    self.omnibarField = NSTextField()
    self.omnibarField.translatesAutoresizingMaskIntoConstraints = false
    self.omnibarField.placeholderString = "Enter URL"
    self.omnibarField.bezelStyle = .roundedBezel
    self.omnibarField.font = .systemFont(ofSize: 13)
    self.omnibarField.focusRingType = .default

    self.backButton = NSButton(
      image: NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back")!,
      target: nil,
      action: nil,
    )
    self.forwardButton = NSButton(
      image: NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Forward")!,
      target: nil,
      action: nil,
    )
    self.reloadButton = NSButton(
      image: NSImage(
        systemSymbolName: "arrow.clockwise",
        accessibilityDescription: "Reload",
      )!,
      target: nil,
      action: nil,
    )
    for button in [self.backButton, self.forwardButton, self.reloadButton] {
      button.translatesAutoresizingMaskIntoConstraints = false
      button.bezelStyle = .texturedRounded
      button.imagePosition = .imageOnly
    }

    super.init(nibName: nil, bundle: nil)

    self.omnibarField.target = self
    self.omnibarField.action = #selector(self.omnibarSubmitted(_:))
    self.omnibarField.delegate = self
    self.backButton.target = self
    self.backButton.action = #selector(self.goBack(_:))
    self.forwardButton.target = self
    self.forwardButton.action = #selector(self.goForward(_:))
    self.reloadButton.target = self
    self.reloadButton.action = #selector(self.reload(_:))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

  override func loadView() {
    let root = NSView()
    root.translatesAutoresizingMaskIntoConstraints = false

    let toolbar = NSStackView(views: [
      self.backButton,
      self.forwardButton,
      self.reloadButton,
      self.omnibarField,
    ])
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    toolbar.orientation = .horizontal
    toolbar.alignment = .centerY
    toolbar.spacing = 6
    toolbar.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    toolbar.setHuggingPriority(.defaultLow, for: .horizontal)
    self.omnibarField.setContentHuggingPriority(.defaultLow, for: .horizontal)

    root.addSubview(toolbar)
    root.addSubview(self.webView)

    NSLayoutConstraint.activate([
      toolbar.topAnchor.constraint(equalTo: root.topAnchor),
      toolbar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: root.trailingAnchor),

      self.webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
      self.webView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      self.webView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      self.webView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
    ])

    self.view = root
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.titleObservation = self.webView.observe(\.title, options: [.new]) { [weak self] _, _ in
      MainActor.assumeIsolated {
        if let title = self?.webView.title, !title.isEmpty {
          self?.view.window?.title = title
        }
      }
    }
    self.urlObservation = self.webView.observe(\.url, options: [.new]) { [weak self] _, _ in
      MainActor.assumeIsolated {
        guard let self, let url = self.webView.url else { return }
        if self.omnibarField.currentEditor() == nil {
          self.omnibarField.stringValue = url.absoluteString
        }
      }
    }
    self.canGoBackObservation = self.webView
      .observe(\.canGoBack, options: [.new, .initial]) { [weak self] _, _ in
        MainActor.assumeIsolated {
          self?.backButton.isEnabled = self?.webView.canGoBack ?? false
        }
      }
    self.canGoForwardObservation = self.webView
      .observe(\.canGoForward, options: [.new, .initial]) { [weak self] _, _ in
        MainActor.assumeIsolated {
          self?.forwardButton.isEnabled = self?.webView.canGoForward ?? false
        }
      }
    self.load(urlString: "https://example.com")
  }

  @objc private func omnibarSubmitted(_ sender: NSTextField) {
    self.load(urlString: sender.stringValue)
  }

  @objc private func goBack(_ sender: Any?) {
    self.webView.goBack()
  }

  @objc private func goForward(_ sender: Any?) {
    self.webView.goForward()
  }

  @objc private func reload(_ sender: Any?) {
    self.webView.reload()
  }

  func load(urlString raw: String) {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let normalized: String
    if trimmed.contains("://") {
      normalized = trimmed
    } else if trimmed.contains("."), !trimmed.contains(" ") {
      normalized = "https://" + trimmed
    } else {
      let q = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
      normalized = "https://duckduckgo.com/?q=" + q
    }
    guard let url = URL(string: normalized) else { return }
    print("[nav] load url=\(url.absoluteString)")
    self.webView.load(URLRequest(url: url))
  }
}
