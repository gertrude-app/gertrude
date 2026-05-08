import DuetSQL
import Tagged

extension BlockerApp {
  struct Supervision: Codable, Sendable, Equatable {
    var id: Id
    var deviceId: IOSDevice.Id
    var udid: String?
    var supervisedAt: Date?
    var profileInstalledAt: Date?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: IOSDevice.Id,
      udid: String? = nil,
      supervisedAt: Date? = nil,
      profileInstalledAt: Date? = nil,
    ) {
      self.id = id
      self.deviceId = deviceId
      self.udid = udid
      self.supervisedAt = supervisedAt
      self.profileInstalledAt = profileInstalledAt
    }
  }
}

extension BlockerApp.Supervision {
  enum Status: String, Codable, Sendable, Equatable {
    case pendingClaim
    case claimed
    case supervised
    case complete
  }

  func status(device: IOSDevice) -> Status {
    if self.profileInstalledAt != nil { return .complete }
    if self.supervisedAt != nil { return .supervised }
    if device.claimedAt != nil { return .claimed }
    return .pendingClaim
  }

  var profileInstalled: Bool {
    self.profileInstalledAt != nil
  }

  var supervised: Bool {
    self.supervisedAt != nil
  }
}

extension BlockerApp.Supervision {
  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}
