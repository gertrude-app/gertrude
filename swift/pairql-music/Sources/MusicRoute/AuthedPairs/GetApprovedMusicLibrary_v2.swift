import Foundation
import PairQL

public struct MusicArtwork: PairNestable {
  public var url: String?
  public var width: Int?
  public var height: Int?
  public var bgColor: String?
  public var textColor1: String?
  public var textColor2: String?
  public var textColor3: String?
  public var textColor4: String?

  public init(
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

public struct MusicEditorialNotes: PairNestable {
  public var tagline: String?
  public var short: String?
  public var standard: String?
  public var name: String?

  public init(
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

public struct MusicCatalogMetadata: PairNestable {
  public var artwork: MusicArtwork?
  public var editorialNotes: MusicEditorialNotes?
  public var appleMusicUrl: String?
  public var genreNames: [String]

  public init(
    artwork: MusicArtwork? = nil,
    editorialNotes: MusicEditorialNotes? = nil,
    appleMusicUrl: String? = nil,
    genreNames: [String] = [],
  ) {
    self.artwork = artwork
    self.editorialNotes = editorialNotes
    self.appleMusicUrl = appleMusicUrl
    self.genreNames = genreNames
  }
}

public struct MusicLibrarySnapshot: PairNestable {
  public static let currentSchemaVersion = 2

  public struct Track: PairNestable {
    public var id: String
    public var title: String
    public var artistName: String
    public var albumId: String
    public var albumTitle: String
    public var artworkUrl: String?
    public var durationInMillis: Int?

    public init(
      id: String,
      title: String,
      artistName: String,
      albumId: String,
      albumTitle: String,
      artworkUrl: String? = nil,
      durationInMillis: Int? = nil,
    ) {
      self.id = id
      self.title = title
      self.artistName = artistName
      self.albumId = albumId
      self.albumTitle = albumTitle
      self.artworkUrl = artworkUrl
      self.durationInMillis = durationInMillis
    }
  }

  public struct Album: PairNestable {
    public var id: String
    public var title: String
    public var artistName: String
    public var artworkUrl: String?
    public var artwork: MusicArtwork?
    public var trackCount: Int?
    public var releaseDate: String?
    public var releaseType: String?
    public var showsArtwork: Bool
    public var addedAt: Date
    public var tracks: [Track]

    public init(
      id: String,
      title: String,
      artistName: String,
      artworkUrl: String? = nil,
      artwork: MusicArtwork? = nil,
      trackCount: Int? = nil,
      releaseDate: String? = nil,
      releaseType: String? = nil,
      showsArtwork: Bool,
      addedAt: Date,
      tracks: [Track],
    ) {
      self.id = id
      self.title = title
      self.artistName = artistName
      self.artworkUrl = artworkUrl
      self.artwork = artwork
      self.trackCount = trackCount
      self.releaseDate = releaseDate
      self.releaseType = releaseType
      self.showsArtwork = showsArtwork
      self.addedAt = addedAt
      self.tracks = tracks
    }
  }

  public struct Artist: PairNestable {
    public var id: String
    public var name: String
    public var catalogMetadata: MusicCatalogMetadata?
    public var releaseAlbumIds: [String]
    public var topSongs: [Track]
    public var addedAt: Date

    public init(
      id: String,
      name: String,
      catalogMetadata: MusicCatalogMetadata? = nil,
      releaseAlbumIds: [String],
      topSongs: [Track],
      addedAt: Date,
    ) {
      self.id = id
      self.name = name
      self.catalogMetadata = catalogMetadata
      self.releaseAlbumIds = releaseAlbumIds
      self.topSongs = topSongs
      self.addedAt = addedAt
    }
  }

  public struct Playlist: PairNestable {
    public struct Entry: PairNestable {
      public var id: UUID
      public var track: Track

      public init(id: UUID, track: Track) {
        self.id = id
        self.track = track
      }
    }

    public var id: UUID
    public var name: String
    public var revision: Int64
    public var createdAt: Date
    public var updatedAt: Date
    public var entries: [Entry]

    public init(
      id: UUID,
      name: String,
      revision: Int64,
      createdAt: Date,
      updatedAt: Date,
      entries: [Entry],
    ) {
      self.id = id
      self.name = name
      self.revision = revision
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.entries = entries
    }
  }

  public var schemaVersion: Int
  public var revision: Int64
  public var generatedAt: Date
  public var albums: [Album]
  public var artists: [Artist]
  public var playlists: [Playlist]

  public init(
    schemaVersion: Int = Self.currentSchemaVersion,
    revision: Int64,
    generatedAt: Date,
    albums: [Album],
    artists: [Artist],
    playlists: [Playlist] = [],
  ) {
    self.schemaVersion = schemaVersion
    self.revision = revision
    self.generatedAt = generatedAt
    self.albums = albums
    self.artists = artists
    self.playlists = playlists
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case revision
    case generatedAt
    case albums
    case artists
    case playlists
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    self.revision = try container.decode(Int64.self, forKey: .revision)
    self.generatedAt = try container.decode(Date.self, forKey: .generatedAt)
    self.albums = try container.decode([Album].self, forKey: .albums)
    self.artists = try container.decode([Artist].self, forKey: .artists)
    self.playlists = try container.decodeIfPresent([Playlist].self, forKey: .playlists) ?? []
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.schemaVersion, forKey: .schemaVersion)
    try container.encode(self.revision, forKey: .revision)
    try container.encode(self.generatedAt, forKey: .generatedAt)
    try container.encode(self.albums, forKey: .albums)
    try container.encode(self.artists, forKey: .artists)
    try container.encode(self.playlists, forKey: .playlists)
  }
}

public struct GetApprovedMusicLibrary_v2: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var knownRevision: Int64?

    public init(knownRevision: Int64? = nil) {
      self.knownRevision = knownRevision
    }
  }

  public enum Output: PairOutput {
    case unchanged(revision: Int64)
    case snapshot(MusicLibrarySnapshot)
  }
}
