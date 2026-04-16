import DuetSQL
import Gertie

struct AlwaysBlockedRule: Codable, Sendable {
  var id: Id
  var groupId: AlwaysBlockedGroup.Id
  var rule: BlockRule
  var comment: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(id: Id = .init(), groupId: AlwaysBlockedGroup.Id, rule: BlockRule, comment: String? = nil) {
    self.id = id
    self.groupId = groupId
    self.rule = rule
    self.comment = comment
  }
}

extension AlwaysBlockedRule {
  func group(in db: any DuetSQL.Client) async throws -> AlwaysBlockedGroup {
    try await db.find(self.groupId)
  }
}
