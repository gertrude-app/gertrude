import DuetSQL
import Tagged

extension Music {
  typealias ArtistId = Tagged<(Music, artistId: ()), String>

  @DuetModel(schema: "music", table: "approved_artists")
  struct ApprovedArtist: Codable, Sendable {
    var id: Id
    var childId: Child.Id
    var appleMusicArtistId: ArtistId
    var name: String
    var catalogMetadata: CatalogMetadata?
    var resolution: ResolvedArtist
    var resolvedAt: Date
    var createdAt = Date()

    init(
      id: Id = .init(),
      childId: Child.Id,
      appleMusicArtistId: ArtistId,
      name: String,
      catalogMetadata: CatalogMetadata? = nil,
      resolution: ResolvedArtist,
      resolvedAt: Date,
    ) {
      self.id = id
      self.childId = childId
      self.appleMusicArtistId = appleMusicArtistId
      self.name = name
      self.catalogMetadata = catalogMetadata
      self.resolution = resolution
      self.resolvedAt = resolvedAt
    }
  }

  struct CatalogMetadata: Codable, Equatable, Sendable {
    var artwork: Artwork?
    var editorialNotes: EditorialNotes?
    var appleMusicUrl: String?
    var genreNames: [String]

    init(
      artwork: Artwork? = nil,
      editorialNotes: EditorialNotes? = nil,
      appleMusicUrl: String? = nil,
      genreNames: [String] = [],
    ) {
      self.artwork = artwork
      self.editorialNotes = editorialNotes
      self.appleMusicUrl = appleMusicUrl
      self.genreNames = genreNames
    }
  }

  struct Artwork: Codable, Equatable, Sendable {
    var url: String?
    var width: Int?
    var height: Int?
    var bgColor: String?
    var textColor1: String?
    var textColor2: String?
    var textColor3: String?
    var textColor4: String?

    init(
      url: String? = nil,
      width: Int? = nil,
      height: Int? = nil,
      bgColor: String? = nil,
      textColor1: String? = nil,
      textColor2: String? = nil,
      textColor3: String? = nil,
      textColor4: String? = nil,
    ) {
      self.url = url
      self.width = width
      self.height = height
      self.bgColor = bgColor
      self.textColor1 = textColor1
      self.textColor2 = textColor2
      self.textColor3 = textColor3
      self.textColor4 = textColor4
    }
  }

  struct EditorialNotes: Codable, Equatable, Sendable {
    var tagline: String?
    var short: String?
    var standard: String?
    var name: String?

    init(
      tagline: String? = nil,
      short: String? = nil,
      standard: String? = nil,
      name: String? = nil,
    ) {
      self.tagline = tagline
      self.short = short
      self.standard = standard
      self.name = name
    }
  }
}

extension Music.ApprovedArtist {
  func child(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }
}
