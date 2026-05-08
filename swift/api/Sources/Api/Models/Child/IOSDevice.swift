import DuetSQL

struct IOSDevice: Codable, Sendable, Equatable {
  var id: Id
  var childId: Child.Id?
  var modelIdentifier: String
  var iosVersion: String
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id,
    childId: Child.Id? = nil,
    modelIdentifier: String,
    iosVersion: String,
  ) {
    self.id = id
    self.childId = childId
    self.modelIdentifier = modelIdentifier
    self.iosVersion = iosVersion
  }
}

extension IOSDevice {
  func shouldUpdateModelIdentifier(to incoming: String) -> Bool {
    incoming.contains(",")
      && !incoming.hasSuffix(",unknown")
      && self.modelIdentifier != incoming
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

  func install(in db: any DuetSQL.Client) async throws -> BlockerApp.Install {
    try await BlockerApp.Install.query()
      .where(.deviceId == self.id)
      .first(in: db)
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
