import AppKit
import WebKit

final class WebViewController: NSViewController, NSTextFieldDelegate, WKNavigationDelegate {
  let webView: WKWebView
  let omnibarField: NSTextField
  private let allowlist = Allowlist.hardcoded
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
    self.webView.navigationDelegate = self
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
    let initial = ProcessInfo.processInfo.environment["SPIKE_INITIAL_URL"]
      ?? "https://example.com"
    self.load(urlString: initial)
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

  func webView(
    _ webView: WKWebView,
    decidePolicyFor action: WKNavigationAction,
    decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void,
  ) {
    let url = action.request.url?.absoluteString ?? "<nil>"
    let kind = switch NavigationPolicy.frameKind(of: action) {
    case .mainFrame: "mainFrame"
    case .subframe: "subframe"
    case .unknownTarget: "unknownTarget"
    }
    let source = action.sourceFrame.request.url?.absoluteString ?? "<none>"
    let type = NavigationPolicy.describe(action.navigationType)
    let decision = NavigationPolicy.decide(action: action, allowlist: self.allowlist)

    switch decision {
    case .allow:
      print("[nav] ALLOW kind=\(kind) type=\(type) url=\(url) source=\(source)")
      decisionHandler(.allow)

    case .blockMainFrame(let reason):
      print(
        "[nav] BLOCK-MAIN kind=\(kind) type=\(type) url=\(url) source=\(source) reason=\(reason)",
      )
      decisionHandler(.cancel)
      let html = NavigationPolicy.blockedPageHTML(reason: reason, attemptedURL: url)
      let baseURL = URL(string: "about:blocked")
      webView.loadHTMLString(html, baseURL: baseURL)

    case .blockSubframe(let reason):
      print(
        "[nav] BLOCK-SUB kind=\(kind) type=\(type) url=\(url) source=\(source) reason=\(reason)",
      )
      decisionHandler(.cancel)

    case .blockUnknownTarget(let reason):
      print(
        "[nav] BLOCK-UNKNOWN kind=\(kind) type=\(type) url=\(url) source=\(source) reason=\(reason)",
      )
      decisionHandler(.cancel)
    }
  }

  func load(urlString raw: String) {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    if trimmed == "spike:embeds" {
      self.loadEmbedsFixture()
      return
    }
    if trimmed == "spike:navtypes" {
      self.loadNavTypesFixture()
      return
    }
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

  private func loadEmbedsFixture() {
    let html = """
    <!doctype html>
    <html>
    <head><meta charset="utf-8"><title>Embeds fixture</title></head>
    <body style="font-family: system-ui; padding: 24px;">
      <h1>Iframe policy fixture</h1>
      <p>Top frame is example.com (allowlisted). Each iframe below targets a different host.</p>

      <h2>Allowed: en.wikipedia.org (allowlisted)</h2>
      <iframe src="https://en.wikipedia.org/wiki/HTTP" width="600" height="240"></iframe>

      <h2>Blocked: youtube.com</h2>
      <iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" width="600" height="240"></iframe>

      <h2>Blocked: facebook.com</h2>
      <iframe src="https://www.facebook.com/plugins/like.php?href=https://example.com" width="600" height="120"></iframe>

      <h2>Blocked: nested-iframe host (httpbin.org embedding youtube)</h2>
      <iframe srcdoc='<iframe src=&quot;https://www.youtube.com/embed/dQw4w9WgXcQ&quot;></iframe>' width="600" height="240"></iframe>
    </body>
    </html>
    """
    print("[nav] load fixture spike:embeds")
    self.webView.loadHTMLString(html, baseURL: URL(string: "https://example.com/spike-embeds"))
  }

  private func loadNavTypesFixture() {
    let html = """
    <!doctype html>
    <html>
    <head><meta charset="utf-8"><title>Nav types fixture</title></head>
    <body style="font-family: system-ui; padding: 24px;">
      <h1>Navigation types fixture</h1>
      <p>All triggers below target blocked hosts so the page persists.</p>
      <a id="badlink" href="https://reddit.com">link to reddit (blocked)</a>
      <form id="form" action="https://twitter.com/search" method="get">
        <input name="q" value="x">
        <button type="submit">submit</button>
      </form>
      <script>
        function step(label, fn, delay) { setTimeout(() => { fn() }, delay) }
        step('bad-link-click', () => document.getElementById('badlink').click(), 500)
        step('location-href-bad', () => { location.href = 'https://twitter.com/jack' }, 1500)
        step('location-replace-bad', () => { location.replace('https://reddit.com/r/foo') }, 2500)
        step('form-submit-bad', () => document.getElementById('form').submit(), 3500)
        step('window-open-bad', () => { window.open('https://reddit.com/popup') }, 4500)
      </script>
    </body>
    </html>
    """
    print("[nav] load fixture spike:navtypes")
    self.webView.loadHTMLString(html, baseURL: URL(string: "https://example.com/spike-navtypes"))
  }
}
