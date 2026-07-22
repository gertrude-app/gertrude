import DuetSQL
import Foundation

extension Music {
  @DuetModel(schema: "music", table: "playlists", clientCreatedAt: true)
  struct Playlist: Codable, Equatable, Sendable {
    var id: Id
    var childId: Child.Id
    var name: String
    var revision: Int64
    var createdAt: Date
    var updatedAt: Date

    init(
      id: Id = .init(),
      childId: Child.Id,
      name: String,
      revision: Int64 = 1,
      createdAt: Date,
      updatedAt: Date,
    ) {
      self.id = id
      self.childId = childId
      self.name = name
      self.revision = revision
      self.createdAt = createdAt
      self.updatedAt = updatedAt
    }
  }

  @DuetModel(schema: "music", table: "playlist_entries", clientCreatedAt: true)
  struct PlaylistEntry: Codable, Equatable, Sendable {
    var id: Id
    var playlistId: Playlist.Id
    var position: Int
    var appleMusicTrackId: TrackId
    var preferredAlbumId: AlbumId
    var createdAt: Date

    init(
      id: Id = .init(),
      playlistId: Playlist.Id,
      position: Int,
      appleMusicTrackId: TrackId,
      preferredAlbumId: AlbumId,
      createdAt: Date,
    ) {
      self.id = id
      self.playlistId = playlistId
      self.position = position
      self.appleMusicTrackId = appleMusicTrackId
      self.preferredAlbumId = preferredAlbumId
      self.createdAt = createdAt
    }
  }
}
