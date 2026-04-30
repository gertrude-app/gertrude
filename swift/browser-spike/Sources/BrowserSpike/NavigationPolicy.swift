import Foundation
import WebKit

enum FrameKind {
  case mainFrame
  case subframe
  case unknownTarget
}

enum PolicyDecision {
  case allow
  case blockMainFrame(reason: String)
  case blockSubframe(reason: String)
  case blockUnknownTarget(reason: String)
}

struct Allowlist {
  let hosts: Set<String>

  static let hardcoded = Allowlist(hosts: [
    "wikipedia.org",
    "github.com",
    "news.ycombinator.com",
    "example.com",
    "example.org",
  ])

  func permits(_ host: String) -> Bool {
    let h = host.lowercased()
    if self.hosts.contains(h) { return true }
    return self.hosts.contains(where: { h.hasSuffix("." + $0) })
  }
}

enum NavigationPolicy {
  @MainActor
  static func frameKind(of action: WKNavigationAction) -> FrameKind {
    guard let target = action.targetFrame else { return .unknownTarget }
    return target.isMainFrame ? .mainFrame : .subframe
  }

  @MainActor
  static func decide(
    action: WKNavigationAction,
    allowlist: Allowlist,
  ) -> PolicyDecision {
    let kind = self.frameKind(of: action)
    guard let url = action.request.url else { return .allow }
    if url.scheme == "about" || url.scheme == "data" || url.scheme == "blob" {
      return .allow
    }
    guard let host = url.host, !host.isEmpty else { return .allow }
    if allowlist.permits(host) { return .allow }
    let reason = "host '\(host)' not in allowlist"
    switch kind {
    case .mainFrame:
      return .blockMainFrame(reason: reason)
    case .subframe:
      return .blockSubframe(reason: reason)
    case .unknownTarget:
      return .blockUnknownTarget(reason: reason)
    }
  }

  static func describe(_ type: WKNavigationType) -> String {
    switch type {
    case .linkActivated: "linkActivated"
    case .formSubmitted: "formSubmitted"
    case .backForward: "backForward"
    case .reload: "reload"
    case .formResubmitted: "formResubmitted"
    case .other: "other"
    @unknown default: "unknown"
    }
  }

  static func blockedPageHTML(reason: String, attemptedURL: String) -> String {
    let escapedURL = attemptedURL
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
    let escapedReason = reason
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
    return """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Blocked by Gertrude</title>
      <style>
        body {
          font-family: -apple-system, system-ui, sans-serif;
          max-width: 560px;
          margin: 80px auto;
          padding: 0 24px;
          color: #1d1d1f;
        }
        h1 { font-size: 28px; margin-bottom: 8px; }
        .subtitle { color: #6e6e73; margin-bottom: 32px; }
        .panel {
          background: #f5f5f7;
          border-radius: 14px;
          padding: 20px 24px;
          font-size: 14px;
        }
        .panel dt { color: #6e6e73; margin-top: 8px; }
        .panel dd { margin: 0 0 8px 0; word-break: break-all; }
      </style>
    </head>
    <body>
      <h1>Blocked</h1>
      <p class="subtitle">This page was blocked by the Gertrude browser policy.</p>
      <div class="panel">
        <dl>
          <dt>URL</dt><dd>\(escapedURL)</dd>
          <dt>Reason</dt><dd>\(escapedReason)</dd>
        </dl>
      </div>
    </body>
    </html>
    """
  }
}
