import DuetSQL
import Foundation
import MusicRoute

extension Music {
  @DuetModel(schema: "music", table: "library_snapshots", clientCreatedAt: true)
  struct LibrarySnapshot: Codable, Sendable {
    var id: Id
    var childId: Child.Id
    var revision: Int64
    var payload: MusicLibrarySnapshot
    var createdAt: Date

    init(
      id: Id = .init(),
      childId: Child.Id,
      revision: Int64,
      payload: MusicLibrarySnapshot,
      createdAt: Date,
    ) {
      self.id = id
      self.childId = childId
      self.revision = revision
      self.payload = payload
      self.createdAt = createdAt
    }
  }
}
