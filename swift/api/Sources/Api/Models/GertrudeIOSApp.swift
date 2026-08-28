import GertieApp
import XSlack

extension GertrudeIOSApp {
  static var appStoreSyncedCases: [Self] {
    [.blocker, .podcasts, .music]
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
