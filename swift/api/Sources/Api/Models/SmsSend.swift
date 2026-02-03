import Duet
import Foundation

struct SmsSend: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var trigger: String
  var countryCode: String
  var createdAt = Date()

  init(id: Id = .init(), parentId: Parent.Id, trigger: String, countryCode: String) {
    self.id = id
    self.parentId = parentId
    self.trigger = trigger
    self.countryCode = countryCode
  }
}
