extension AppStore {
  enum GertrudeApp: String, Sendable, Codable, CaseIterable {
    case blocker
    case podcasts

    var appleId: String {
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
  }
}
