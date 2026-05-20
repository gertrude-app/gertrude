import Dependencies
import DuetSQL
import Tagged

extension PodcastApp {
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
}
