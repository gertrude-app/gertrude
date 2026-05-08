import DuetSQL
import Tagged

extension BlockerApp {
  struct Supervision: Codable, Sendable, Equatable {
    var id: Id
    var deviceId: IOSDevice.Id
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
      deviceId: IOSDevice.Id,
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

extension BlockerApp.Supervision {
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

extension BlockerApp.Supervision {
  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}
