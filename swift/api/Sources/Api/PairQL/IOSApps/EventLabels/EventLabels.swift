import GertieApp

enum EventLabel {
  static func name(_ app: GertrudeIOSApp, _ eventId: String) -> String? {
    switch app {
    case .blocker: blocker(eventId)
    case .podcasts: podcast(eventId)
    case .music: music(eventId)
    }
  }
}
