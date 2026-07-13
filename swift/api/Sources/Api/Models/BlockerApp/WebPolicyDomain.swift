import DuetSQL
import Foundation

extension BlockerApp {
  @DuetModel(schema: "blocker_app", table: "web_policy_domains")
  struct WebPolicyDomain: Codable, Sendable {
    var id: Id
    var deviceId: IOSDevice.Id
    var domain: String
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), deviceId: IOSDevice.Id, domain: String) {
      self.id = id
      self.deviceId = deviceId
      self.domain = domain
    }
  }
}
