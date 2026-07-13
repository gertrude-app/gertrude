import Dependencies
import DuetSQL
import Tagged

extension PodcastApp {
  @DuetModel(schema: "podcast_app", table: "tokens")
  struct Token: Codable, Sendable {
    var id: Id
    var installId: PodcastApp.Install.Id
    var value: Value
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), installId: PodcastApp.Install.Id, value: Value? = nil) {
      self.id = id
      self.installId = installId
      self.value = value ?? .init(get(dependency: \.uuid)())
    }
  }
}

extension PodcastApp.Token {
  func install(in db: any DuetSQL.Client) async throws -> PodcastApp.Install {
    try await PodcastApp.Install.query()
      .where(.id == self.installId)
      .first(in: db)
  }

  static func connectedDeviceIds(
    among deviceIds: [IOSDevice.Id],
    in db: any DuetSQL.Client,
  ) async throws -> Set<IOSDevice.Id> {
    guard !deviceIds.isEmpty else { return [] }
    let installs = try await PodcastApp.Install.query()
      .where(.deviceId |=| deviceIds)
      .all(in: db)
    guard !installs.isEmpty else { return [] }
    let tokenedInstallIds = try await Set(
      PodcastApp.Token.query()
        .where(.installId |=| installs.map(\.id))
        .all(in: db)
        .map(\.installId),
    )
    return Set(installs.filter { tokenedInstallIds.contains($0.id) }.map(\.deviceId))
  }
}
