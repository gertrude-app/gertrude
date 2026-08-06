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
    var artwork: Artwork?
    var trackCount: Int?
    var showsArtwork: Bool
    var resolution: ResolvedAlbum
    var resolvedAt: Date
    var createdAt = Date()

    init(
      id: Id = .init(),
      childId: Child.Id,
      appleMusicAlbumId: AlbumId,
      title: String,
      artistName: String,
      artworkUrl: String? = nil,
      artwork: Artwork? = nil,
      trackCount: Int? = nil,
      showsArtwork: Bool = true,
      resolution: ResolvedAlbum,
      resolvedAt: Date,
    ) {
      self.id = id
      self.childId = childId
      self.appleMusicAlbumId = appleMusicAlbumId
      self.title = title
      self.artistName = artistName
      self.artworkUrl = artworkUrl
      self.artwork = artwork
      self.trackCount = trackCount
      self.showsArtwork = showsArtwork
      self.resolution = resolution
      self.resolvedAt = resolvedAt
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
