import DuetSQL
import Tagged

extension IOSApp {
  struct Supervision: Codable, Sendable, Equatable {
    var id: Id
    var deviceId: Device.Id
    var claimCode: Int
    var claimCodeExpiresAt: Date
    var udid: String?
    var claimedAt: Date?
    var supervisedAt: Date?
    var profileInstalledAt: Date?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: Device.Id,
      claimCode: Int,
      claimCodeExpiresAt: Date,
      udid: String? = nil,
      claimedAt: Date? = nil,
      supervisedAt: Date? = nil,
      profileInstalledAt: Date? = nil,
    ) {
      self.id = id
      self.deviceId = deviceId
      self.claimCode = claimCode
      self.claimCodeExpiresAt = claimCodeExpiresAt
      self.udid = udid
      self.claimedAt = claimedAt
      self.supervisedAt = supervisedAt
      self.profileInstalledAt = profileInstalledAt
    }
  }
}

extension IOSApp.Supervision {
  enum Status: String, Codable, Sendable, Equatable {
    case pendingClaim
    case claimed
    case supervised
    case complete
  }

  var status: Status {
    if self.profileInstalledAt != nil { return .complete }
    if self.supervisedAt != nil { return .supervised }
    if self.claimedAt != nil { return .claimed }
    return .pendingClaim
  }

  var profileInstalled: Bool {
    self.profileInstalledAt != nil
  }

  var supervised: Bool {
    self.supervisedAt != nil
  }

  var claimed: Bool {
    self.claimedAt != nil
  }
}

extension IOSApp.Supervision {
  func device(in db: any DuetSQL.Client) async throws -> IOSApp.Device {
    try await IOSApp.Device.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}
