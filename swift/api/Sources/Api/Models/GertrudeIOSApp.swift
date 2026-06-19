import XSlack

enum GertrudeIOSApp: String, Sendable, Codable, CaseIterable {
  case blocker
  case podcasts
  case music

  static var appStoreSyncedCases: [Self] {
    [.blocker, .podcasts]
  }

  var appStoreAppleId: String {
    switch self {
    case .blocker: "6736368820"
    case .podcasts: "6753187429"
    case .music: ""
    }
  }

  var marketingName: String {
    switch self {
    case .blocker: "Gertrude Blocker"
    case .podcasts: "Gertrude AM"
    case .music: "Gertrude Music"
    }
  }

  var claimLogLabel: String {
    switch self {
    case .blocker: "iOS supervision"
    case .podcasts: "Gertrude AM"
    case .music: "Gertrude Music"
    }
  }

  var slackChannel: XSlack.Slack.Client.InternalChannel {
    switch self {
    case .blocker: .info
    case .podcasts: .podcasts
    case .music: .info
    }
  }

  var claimPendingQueryKey: String {
    switch self {
    case .blocker: "claimPendingSupervision"
    case .podcasts: "claimPendingAmDevice"
    case .music: "claimPendingMusicDevice"
    }
  }

  func claimFunnelRedirectPath(code: Int) -> String {
    switch self {
    case .blocker: "/supervise-device/\(code)/claim"
    case .podcasts: "/claim-am-device/\(code)/claim"
    case .music: "/claim-music-device/\(code)/claim"
    }
  }
}
