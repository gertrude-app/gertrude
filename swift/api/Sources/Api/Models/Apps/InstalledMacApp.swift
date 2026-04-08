import Duet

struct InstalledMacApp: Codable, Sendable {
  var id: Id
  var childId: Child.Id
  var computerId: Computer.Id
  var macAppId: CatalogedApp.Id
  var createdAt = Date()
  var updatedAt = Date()

  init(id: Id = .init(), childId: Child.Id, computerId: Computer.Id, macAppId: CatalogedApp.Id) {
    self.id = id
    self.childId = childId
    self.computerId = computerId
    self.macAppId = macAppId
  }
}
