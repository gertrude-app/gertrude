import GertieApp
import XSlack

extension GertrudeIOSApp {
  static var appStoreSyncedCases: [Self] {
    [.blocker, .podcasts, .music]
  }

  var appStoreAppleId: String {
    switch self {
    case .blocker: "6736368820"
    case .podcasts: "6753187429"
    case .music: "6782194077"
    }
  }

  var marketingName: String {
    switch self {
    case .blocker: "Gertrude Blocker"
    case .podcasts: "Gertrude Podcasts"
    case .music: "Gertrude Music"
    }
  }

  var slackChannel: XSlack.Slack.Client.InternalChannel {
    switch self {
    case .blocker: .info
    case .podcasts: .podcasts
    case .music: .music
    }
  }
}
