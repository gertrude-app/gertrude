import Foundation

extension AppStore {
  struct RatingSnapshot: Codable, Sendable {
    var id: Id
    var app: GertrudeIOSApp
    var averageRating: Double
    var totalCount: Int
    var reviewCount: Int
    var createdAt = Date()

    init(
      id: Id = .init(),
      app: GertrudeIOSApp,
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
