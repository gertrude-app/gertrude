import DuetSQL
import GertieBlocker

extension BlockerApp {
  struct BlockRule: Codable, Sendable {
    var id: Id
    var deviceId: IOSDevice.Id?
    var rule: GertieBlocker.BlockRule
    var groupId: BlockGroup.Id?
    var comment: String?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: IOSDevice.Id? = nil,
      rule: GertieBlocker.BlockRule,
      groupId: BlockGroup.Id? = nil,
      comment: String? = nil,
    ) {
      self.id = id
      self.deviceId = deviceId
      self.rule = rule
      self.groupId = groupId
      self.comment = comment
    }
  }
}

extension BlockerApp.BlockRule {
  func device(in db: any DuetSQL.Client) async throws -> IOSDevice? {
    guard let deviceId = self.deviceId else {
      return nil
    }
    return try await IOSDevice.query()
      .where(.id == deviceId)
      .first(in: db)
  }
}
