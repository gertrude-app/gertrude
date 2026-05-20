import XSlack

enum GertrudeIOSApp: String, Sendable, Codable, CaseIterable {
  case blocker
  case podcasts

  var appStoreAppleId: String {
    switch self {
    case .blocker: "6736368820"
    case .podcasts: "6753187429"
    }
  }

  var marketingName: String {
    switch self {
    case .blocker: "Gertrude Blocker"
    case .podcasts: "Gertrude AM"
    }
  }

  var claimLogLabel: String {
    switch self {
    case .blocker: "iOS supervision"
    case .podcasts: "Gertrude AM"
    }
  }

  var slackChannel: XSlack.Slack.Client.InternalChannel {
    switch self {
    case .blocker: .info
    case .podcasts: .podcasts
    }
  }

  var claimPendingQueryKey: String {
    switch self {
    case .blocker: "claimPendingSupervision"
    case .podcasts: "claimPendingAmDevice"
    }
  }

  func claimFunnelRedirectPath(code: Int) -> String {
    switch self {
    case .blocker: "/supervise-device/\(code)/claim"
    case .podcasts: "/claim-am-device/\(code)/claim"
    }
  }
}
