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
    var isSupervised: Bool
    var udid: String?
    var isProfileInstalled: Bool
    var supervisionClaimCode: Int?
    var claimCodeExpiresAt: Date?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id,
      childId: Child.Id? = nil,
      modelIdentifier: String,
      appVersion: String,
      iosVersion: String,
      webPolicy: String = "blockAll",
      isSupervised: Bool = false,
      udid: String? = nil,
      isProfileInstalled: Bool = false,
      supervisionClaimCode: Int? = nil,
      claimCodeExpiresAt: Date? = nil,
    ) {
      self.id = id
      self.childId = childId
      self.modelIdentifier = modelIdentifier
      self.appVersion = appVersion
      self.iosVersion = iosVersion
      self.webPolicy = webPolicy
      self.isSupervised = isSupervised
      self.udid = udid
      self.isProfileInstalled = isProfileInstalled
      self.supervisionClaimCode = supervisionClaimCode
      self.claimCodeExpiresAt = claimCodeExpiresAt
    }
  }
}

extension IOSApp.Device {
  static func ensureExists(
    id: Id,
    modelIdentifier: String,
    iosVersion: String,
    appVersion: String = "0.0.0",
    in db: any DuetSQL.Client,
  ) async throws {
    let existing = try? await db.find(id)
    if existing == nil {
      try await db.create(Self(
        id: id,
        modelIdentifier: modelIdentifier,
        appVersion: appVersion,
        iosVersion: iosVersion,
      ))
    }
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
