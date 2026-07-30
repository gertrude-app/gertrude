import DuetSQL

extension Music {
  @DuetModel(schema: "music", table: "approved_tracks")
  struct ApprovedTrack: Codable, Sendable {
    var id: Id
    var childId: Child.Id
    var appleMusicTrackId: TrackId
    var preferredAlbumId: AlbumId
    var resolution: ResolvedTrackGrant
    var showsArtwork: Bool
    var resolvedAt: Date
    var createdAt = Date()

    init(
      id: Id = .init(),
      childId: Child.Id,
      appleMusicTrackId: TrackId,
      preferredAlbumId: AlbumId,
      resolution: ResolvedTrackGrant,
      showsArtwork: Bool = true,
      resolvedAt: Date,
    ) {
      self.id = id
      self.childId = childId
      self.appleMusicTrackId = appleMusicTrackId
      self.preferredAlbumId = preferredAlbumId
      self.resolution = resolution
      self.showsArtwork = showsArtwork
      self.resolvedAt = resolvedAt
    }
  }
}

extension Music.ApprovedTrack {
  func validateResolution() throws {
    try self.resolution.validate(
      appleMusicTrackId: self.appleMusicTrackId,
      preferredAlbumId: self.preferredAlbumId,
    )
  }

  func child(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }
}
