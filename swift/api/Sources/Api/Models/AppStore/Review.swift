import Foundation

extension AppStore {
  struct Review: Codable, Sendable {
    var id: Id
    var appleId: String
    var app: GertrudeIOSApp
    var rating: Int
    var title: String?
    var body: String
    var reviewerNickname: String
    var territory: String
    var reviewCreatedAt: Date
    var createdAt: Date = .init()

    init(
      id: Id = .init(),
      appleId: String,
      app: GertrudeIOSApp,
      rating: Int,
      title: String?,
      body: String,
      reviewerNickname: String,
      territory: String,
      reviewCreatedAt: Date,
    ) {
      self.id = id
      self.appleId = appleId
      self.app = app
      self.rating = rating
      self.title = title
      self.body = body
      self.reviewerNickname = reviewerNickname
      self.territory = territory
      self.reviewCreatedAt = reviewCreatedAt
    }
  }
}
