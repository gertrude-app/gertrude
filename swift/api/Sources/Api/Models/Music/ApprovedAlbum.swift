import DuetSQL
import Tagged

extension Music {
  typealias AlbumId = Tagged<(Music, albumId: ()), String>
  typealias TrackId = Tagged<(Music, trackId: ()), String>

  @DuetModel(schema: "music", table: "approved_albums")
  struct ApprovedAlbum: Codable, Sendable {
    var id: Id
    var childId: Child.Id
    var appleMusicAlbumId: AlbumId
    var title: String
    var artistName: String
    var artworkUrl: String?
    var trackCount: Int?
    var showsArtwork: Bool
    var createdAt = Date()

    init(
      id: Id = .init(),
      childId: Child.Id,
      appleMusicAlbumId: AlbumId,
      title: String,
      artistName: String,
      artworkUrl: String? = nil,
      trackCount: Int? = nil,
      showsArtwork: Bool = true,
    ) {
      self.id = id
      self.childId = childId
      self.appleMusicAlbumId = appleMusicAlbumId
      self.title = title
      self.artistName = artistName
      self.artworkUrl = artworkUrl
      self.trackCount = trackCount
      self.showsArtwork = showsArtwork
    }
  }
}

extension Music.ApprovedAlbum {
  func child(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }
}
