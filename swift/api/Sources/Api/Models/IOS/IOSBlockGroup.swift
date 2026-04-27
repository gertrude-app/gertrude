import Duet
import GertieIOS

extension IOSApp {
  struct BlockGroup: Codable, Sendable {
    var id: Id
    var name: String
    var description: String
    var longDescription: String
    var imageSlug: String?
    var optIn: Bool
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      name: String,
      description: String,
      longDescription: String,
      imageSlug: String? = nil,
      optIn: Bool = false,
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.longDescription = longDescription
      self.imageSlug = imageSlug
      self.optIn = optIn
    }
  }
}
