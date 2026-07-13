import DuetSQL
import Gertie

@DuetModel(schema: "child", table: "always_blocked_rules")
struct ChildAlwaysBlockedRule: Codable, Sendable {
  var id: Id
  var childId: Child.Id
  var rule: BlockRule
  var comment: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(id: Id = .init(), childId: Child.Id, rule: BlockRule, comment: String? = nil) {
    self.id = id
    self.childId = childId
    self.rule = rule
    self.comment = comment
  }
}
