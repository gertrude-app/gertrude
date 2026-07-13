import Dependencies
import DuetSQL
import Foundation
import Tagged

extension MusicApp {
  @DuetModel(schema: "music_app", table: "tokens")
  struct Token: Codable, Sendable {
    var id: Id
    var installId: MusicApp.Install.Id
    var value: Value
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), installId: MusicApp.Install.Id, value: Value? = nil) {
      self.id = id
      self.installId = installId
      self.value = value ?? .init(get(dependency: \.uuid)())
    }
  }
}

extension MusicApp.Token {
  func install(in db: any DuetSQL.Client) async throws -> MusicApp.Install {
    try await MusicApp.Install.query()
      .where(.id == self.installId)
      .first(in: db)
  }

  static func connectedDeviceIds(
    among deviceIds: [IOSDevice.Id],
    in db: any DuetSQL.Client,
  ) async throws -> Set<IOSDevice.Id> {
    guard !deviceIds.isEmpty else { return [] }
    let installs = try await MusicApp.Install.query()
      .where(.deviceId |=| deviceIds)
      .all(in: db)
    guard !installs.isEmpty else { return [] }
    let tokenedInstallIds = try await Set(
      MusicApp.Token.query()
        .where(.installId |=| installs.map(\.id))
        .all(in: db)
        .map(\.installId),
    )
    return Set(installs.filter { tokenedInstallIds.contains($0.id) }.map(\.deviceId))
  }
}
