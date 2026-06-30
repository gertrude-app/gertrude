enum ClaimIntent: String, Codable, Sendable, Equatable, CaseIterable {
  case blockerSupervise
  case blockerConnect
  case podcasts
  case music

  var app: GertrudeIOSApp {
    switch self {
    case .blockerSupervise, .blockerConnect: .blocker
    case .podcasts: .podcasts
    case .music: .music
    }
  }

  var requiresSupervision: Bool {
    self == .blockerSupervise
  }

  var claimLogLabel: String {
    switch self {
    case .blockerSupervise: "iOS supervision"
    case .blockerConnect: "iOS connect"
    case .podcasts: "Gertrude Podcasts"
    case .music: "Gertrude Music"
    }
  }

  var funnelPathSegment: String {
    switch self {
    case .blockerSupervise: "supervise-device"
    case .blockerConnect: "claim-blocker-device"
    case .podcasts: "claim-podcasts-device"
    case .music: "claim-music-device"
    }
  }

  var claimPendingQueryKey: String {
    switch self {
    case .blockerSupervise: "claimPendingSupervision"
    case .blockerConnect: "claimPendingBlocker"
    case .podcasts: "claimPendingPodcastsDevice"
    case .music: "claimPendingMusicDevice"
    }
  }

  func claimFunnelPath(code: Int) -> String {
    "/\(self.funnelPathSegment)/\(code)/claim"
  }
}
