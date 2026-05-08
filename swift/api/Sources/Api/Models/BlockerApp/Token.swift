import Dependencies
import DuetSQL
import Tagged

extension BlockerApp {
  struct Token: Codable, Sendable {
    var id: Id
    var deviceId: IOSDevice.Id
    var value: Value
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), deviceId: IOSDevice.Id, value: Value? = nil) {
      self.id = id
      self.deviceId = deviceId
      self.value = value ?? .init(get(dependency: \.uuid)())
    }
  }
}

// loaders

extension BlockerApp.Token {
  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}
