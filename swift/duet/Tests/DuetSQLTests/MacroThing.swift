import DuetSQL
import Foundation

@DuetModel(schema: "public", table: "macro_things")
struct MacroThing: Codable {
  var id: Id
  var name: String
  var count: Int?
  var customEnum: Thing.CustomEnum
  var optionalCustomEnum: Thing.CustomEnum?
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var isNamed: Bool {
    !self.name.isEmpty
  }

  init(
    id: Id = .init(UUID()),
    name: String = "foo",
    count: Int? = nil,
    customEnum: Thing.CustomEnum = .foo,
    optionalCustomEnum: Thing.CustomEnum? = nil,
    deletedAt: Date? = nil,
  ) {
    self.id = id
    self.name = name
    self.count = count
    self.customEnum = customEnum
    self.optionalCustomEnum = optionalCustomEnum
    self.deletedAt = deletedAt
  }
}
