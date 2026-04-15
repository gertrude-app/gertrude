import DuetSQL

struct AlwaysBlockedGroup: Codable, Sendable {
  var id: Id
  var name: String
  var description: String
  var longDescription: String
  var createdAt = Date()
  var updatedAt = Date()

  init(id: Id = .init(), name: String, description: String, longDescription: String) {
    self.id = id
    self.name = name
    self.description = description
    self.longDescription = longDescription
  }
}

extension AlwaysBlockedGroup {
  func rules(in db: any DuetSQL.Client) async throws -> [AlwaysBlockedRule] {
    try await AlwaysBlockedRule.query()
      .where(.groupId == self.id)
      .all(in: db)
  }
}
