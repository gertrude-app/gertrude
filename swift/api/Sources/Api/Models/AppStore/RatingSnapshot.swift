import Foundation

extension AppStore {
  struct RatingSnapshot: Codable, Sendable {
    var id: Id
    var app: GertrudeApp
    var averageRating: Double
    var totalCount: Int
    var reviewCount: Int
    var createdAt: Date = .init()

    init(
      id: Id = .init(),
      app: GertrudeApp,
      averageRating: Double,
      totalCount: Int,
      reviewCount: Int,
    ) {
      self.id = id
      self.app = app
      self.averageRating = averageRating
      self.totalCount = totalCount
      self.reviewCount = reviewCount
    }
  }
}
