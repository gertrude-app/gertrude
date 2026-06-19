import DuetSQL

struct IOSDevice: Codable, Sendable, Equatable {
  var id: Id
  var childId: Child.Id?
  var modelIdentifier: String
  var iosVersion: String
  var claimCode: Int?
  var claimCodeExpiresAt: Date?
  var claimedAt: Date?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id,
    childId: Child.Id? = nil,
    modelIdentifier: String,
    iosVersion: String,
    claimCode: Int? = nil,
    claimCodeExpiresAt: Date? = nil,
    claimedAt: Date? = nil,
  ) {
    self.id = id
    self.childId = childId
    self.modelIdentifier = modelIdentifier
    self.iosVersion = iosVersion
    self.claimCode = claimCode
    self.claimCodeExpiresAt = claimCodeExpiresAt
    self.claimedAt = claimedAt
  }
}

extension IOSDevice {
  func shouldUpdateModelIdentifier(to incoming: String) -> Bool {
    incoming.contains(",")
      && !incoming.hasSuffix(",unknown")
      && self.modelIdentifier != incoming
  }

  @discardableResult
  static func ensureAppInstallDevice(
    id: Id,
    modelIdentifier: String,
    iosVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> IOSDevice {
    var device = try await db.findOrCreate(
      IOSDevice(id: id, modelIdentifier: modelIdentifier, iosVersion: iosVersion),
      conflictOn: [.id],
    )
    var saveDevice = false
    if device.shouldUpdateModelIdentifier(to: modelIdentifier) {
      device.modelIdentifier = modelIdentifier
      saveDevice = true
    }
    if device.iosVersion != iosVersion {
      device.iosVersion = iosVersion
      saveDevice = true
    }
    if saveDevice {
      try await db.update(device)
    }
    return device
  }
}

protocol IOSAppInstall: Model {
  var deviceId: IOSDevice.Id { get set }
  var appVersion: String { get set }

  init(deviceId: IOSDevice.Id, appVersion: String)

  static var deviceIdColumn: ColumnName { get }
  static var appVersionColumn: ColumnName { get }
  static var updatedAtColumn: ColumnName { get }
}

extension IOSAppInstall {
  @discardableResult
  static func ensureExists(
    deviceId: IOSDevice.Id,
    modelIdentifier: String,
    iosVersion: String,
    appVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> Self {
    try await db.withTransaction { txn in
      try await IOSDevice.ensureAppInstallDevice(
        id: deviceId,
        modelIdentifier: modelIdentifier,
        iosVersion: iosVersion,
        in: txn,
      )
      let conflictTarget = deviceIdColumn
      let appVersionTarget = appVersionColumn
      let updatedAtTarget = updatedAtColumn
      return try await txn.upsert(
        Self(deviceId: deviceId, appVersion: appVersion),
        conflictOn: [conflictTarget],
        do: .updateRaw { c in
          """
          \(c.col(appVersionTarget)) = \(c.excluded(appVersionTarget)),
          \(c.col(updatedAtTarget)) = CASE
            WHEN \(c.target(appVersionTarget)) IS DISTINCT FROM \(c.excluded(appVersionTarget))
            THEN CURRENT_TIMESTAMP
            ELSE \(c.target(updatedAtTarget))
          END
          """
        },
      )
    }
  }

  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}

// loaders

extension IOSDevice {
  func child(in db: any DuetSQL.Client) async throws -> Child? {
    guard let childId = self.childId else { return nil }
    return try await Child.query()
      .where(.id == childId)
      .first(in: db)
  }

  func blockerInstall(in db: any DuetSQL.Client) async throws -> BlockerApp.Install {
    try await BlockerApp.Install.query()
      .where(.deviceId == self.id)
      .first(in: db)
  }

  func podcastInstall(in db: any DuetSQL.Client) async throws -> PodcastApp.Install? {
    try await PodcastApp.Install.query()
      .where(.deviceId == self.id)
      .all(in: db)
      .first
  }

  func musicInstall(in db: any DuetSQL.Client) async throws -> MusicApp.Install? {
    try await MusicApp.Install.query()
      .where(.deviceId == self.id)
      .all(in: db)
      .first
  }

  func blockGroups(in db: any DuetSQL.Client) async throws -> [BlockerApp.BlockGroup] {
    let pivots = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == self.id)
      .all(in: db)
    return try await BlockerApp.BlockGroup.query()
      .where(.id |=| pivots.map(\.blockGroupId))
      .all(in: db)
  }

  func blockRules(in db: any DuetSQL.Client) async throws -> [BlockerApp.BlockRule] {
    try await BlockerApp.BlockRule.query()
      .where(.deviceId == self.id)
      .all(in: db)
  }

  func webPolicyDomains(in db: any DuetSQL.Client) async throws -> [BlockerApp.WebPolicyDomain] {
    try await BlockerApp.WebPolicyDomain.query()
      .where(.deviceId == self.id)
      .all(in: db)
  }

  func supervision(in db: any DuetSQL.Client) async throws -> BlockerApp.Supervision? {
    try? await BlockerApp.Supervision.query()
      .where(.deviceId == self.id)
      .first(in: db)
  }
}
