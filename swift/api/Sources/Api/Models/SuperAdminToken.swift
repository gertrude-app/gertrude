import Dependencies
import Duet
import DuetSQL
import Tagged

@DuetModel(schema: "system", table: "super_admin_tokens")
struct SuperAdminToken: Codable, Sendable {
  var id: Id
  var value: Value
  var createdAt = Date()
  var deletedAt: Date

  init(id: Id? = nil, value: Value? = nil, deletedAt: Date? = nil) {
    @Dependency(\.uuid) var uuid
    self.id = id ?? .init(uuid())
    self.value = value ?? .init(uuid())
    self.deletedAt = deletedAt ?? Date(addingDays: 60)
  }
}

extension SuperAdminToken {
  typealias Value = Tagged<(SuperAdminToken, value: ()), UUID>
}
