import DuetSQL
import GertieIOS

extension IOSApp {
  struct Device: Codable, Sendable, Equatable {
    var id: Id
    var childId: Child.Id?
    var modelIdentifier: String
    var appVersion: String
    var iosVersion: String
    var webPolicy: String
    var isProfileLocked: Bool
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id,
      childId: Child.Id? = nil,
      modelIdentifier: String,
      appVersion: String,
      iosVersion: String,
      webPolicy: String = "blockAll",
      isProfileLocked: Bool = true,
    ) {
      self.id = id
      self.childId = childId
      self.modelIdentifier = modelIdentifier
      self.appVersion = appVersion
      self.iosVersion = iosVersion
      self.webPolicy = webPolicy
      self.isProfileLocked = isProfileLocked
    }
  }
}

extension IOSApp.Device {
  func shouldUpdateModelIdentifier(to incoming: String) -> Bool {
    incoming.contains(",")
      && !incoming.hasSuffix(",unknown")
      && self.modelIdentifier != incoming
  }
}

extension IOSApp.Device {
  @discardableResult
  static func ensureExists(
    id: Id,
    modelIdentifier: String,
    iosVersion: String,
    appVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> IOSApp.Device {
    if var existing = try? await db.find(id) {
      if existing.shouldUpdateModelIdentifier(to: modelIdentifier) {
        existing.modelIdentifier = modelIdentifier
        try await db.update(existing)
      }
      return existing
    }
    return try await db.create(IOSApp.Device(
      id: id,
      modelIdentifier: modelIdentifier,
      appVersion: appVersion,
      iosVersion: iosVersion,
    ))
  }
}

// loaders

extension IOSApp.Device {
  func child(in db: any DuetSQL.Client) async throws -> Child? {
    guard let childId = self.childId else { return nil }
    return try await Child.query()
      .where(.id == childId)
      .first(in: db)
  }

  func blockGroups(in db: any DuetSQL.Client) async throws -> [IOSApp.BlockGroup] {
    let pivots = try await IOSApp.DeviceBlockGroup.query()
      .where(.deviceId == self.id)
      .all(in: db)
    return try await IOSApp.BlockGroup.query()
      .where(.id |=| pivots.map(\.blockGroupId))
      .all(in: db)
  }

  func blockRules(in db: any DuetSQL.Client) async throws -> [IOSApp.BlockRule] {
    try await IOSApp.BlockRule.query()
      .where(.deviceId == self.id)
      .all(in: db)
  }

  func webPolicyDomains(in db: any DuetSQL.Client) async throws -> [IOSApp.WebPolicyDomain] {
    try await IOSApp.WebPolicyDomain.query()
      .where(.deviceId == self.id)
      .all(in: db)
  }

  func supervision(in db: any DuetSQL.Client) async throws -> IOSApp.Supervision? {
    try? await IOSApp.Supervision.query()
      .where(.deviceId == self.id)
      .first(in: db)
  }

  func webContentFilterPolicy(
    in db: any DuetSQL.Client,
  ) async throws -> WebContentFilterPolicy {
    let domains = try await self.webPolicyDomains(in: db).map(\.domain)
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
        .error("unexpected web policy `\(self.webPolicy)` for ios device \(self.id)")
      return .blockAll
    }
  }
}
