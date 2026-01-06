import Foundation

extension AppStore {
  struct RatingEvent: Codable, Sendable {
    var id: Id
    var app: GertrudeApp
    var stars: Int
    var createdAt: Date = .init()

    init(id: Id = .init(), app: GertrudeApp, stars: Int) {
      self.id = id
      self.app = app
      self.stars = stars
    }
  }
}
