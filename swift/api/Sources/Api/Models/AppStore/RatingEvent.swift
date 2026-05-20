import Foundation

extension AppStore {
  struct RatingEvent: Codable, Sendable {
    var id: Id
    var app: GertrudeIOSApp
    var stars: Int
    var createdAt: Date = .init()

    init(id: Id = .init(), app: GertrudeIOSApp, stars: Int) {
      self.id = id
      self.app = app
      self.stars = stars
    }
  }
}
