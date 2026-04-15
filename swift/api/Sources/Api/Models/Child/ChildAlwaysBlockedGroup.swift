import Duet

struct ChildAlwaysBlockedGroup: Codable, Sendable {
  var id: Id
  var childId: Child.Id
  var groupId: AlwaysBlockedGroup.Id
  var createdAt = Date()

  init(id: Id = .init(), childId: Child.Id, groupId: AlwaysBlockedGroup.Id) {
    self.id = id
    self.childId = childId
    self.groupId = groupId
  }
}
