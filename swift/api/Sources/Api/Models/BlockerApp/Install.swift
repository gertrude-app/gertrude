import DuetSQL
import GertieBlocker

extension BlockerApp {
  @DuetModel(schema: "blocker_app", table: "installs")
  struct Install: Codable, Sendable, Equatable {
    var id: Id
    var deviceId: IOSDevice.Id
    var appVersion: String
    var webPolicy: String
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: IOSDevice.Id,
      appVersion: String,
      webPolicy: String = "blockAll",
    ) {
      self.id = id
      self.deviceId = deviceId
      self.appVersion = appVersion
      self.webPolicy = webPolicy
    }
  }
}

extension BlockerApp.Install {
  @discardableResult
  static func ensureExists(
    deviceId: IOSDevice.Id,
    modelIdentifier: String,
    iosVersion: String,
    appVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> BlockerApp.Install {
    if var device = try? await db.find(deviceId) as IOSDevice {
      var dirty = false
      if device.shouldUpdateModelIdentifier(to: modelIdentifier) {
        device.modelIdentifier = modelIdentifier
        dirty = true
      }
      if device.iosVersion != iosVersion {
        device.iosVersion = iosVersion
        dirty = true
      }
      if dirty {
        try await db.update(device)
      }
    } else {
      try await db.create(IOSDevice(
        id: deviceId,
        modelIdentifier: modelIdentifier,
        iosVersion: iosVersion,
      ))
    }

    if var install = try? await BlockerApp.Install.query()
      .where(.deviceId == deviceId)
      .first(in: db) {
      if install.appVersion != appVersion {
        install.appVersion = appVersion
        try await db.update(install)
      }
      return install
    }
    return try await db.create(BlockerApp.Install(
      deviceId: deviceId,
      appVersion: appVersion,
    ))
  }

  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }

  func token(in db: any DuetSQL.Client) async throws -> BlockerApp.Token? {
    try await BlockerApp.Token.query()
      .where(.installId == self.id)
      .first(in: db)
  }

  func hasToken(in db: any DuetSQL.Client) async throws -> Bool {
    try await BlockerApp.Token.query()
      .where(.installId == self.id)
      .exists(in: db)
  }

  func webContentFilterPolicy(
    in db: any DuetSQL.Client,
  ) async throws -> WebContentFilterPolicy {
    let domains = try await BlockerApp.WebPolicyDomain.query()
      .where(.deviceId == self.deviceId)
      .all(in: db)
      .map(\.domain)
    switch self.webPolicy {
    case "allowAll":
      return .allowAll
    case "blockAdult":
      return .blockAdult
    case "blockAdultAnd":
      return .blockAdultAnd(Set(domains))
    case "blockAllExcept":
      return .blockAllExcept(Set(domains))
    case "blockAll":
      return .blockAll
    default:
      await with(dependency: \.slack)
        .error("unexpected web policy `\(self.webPolicy)` for ios device \(self.deviceId)")
      return .blockAll
    }
  }
}
