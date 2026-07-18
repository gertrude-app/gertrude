import Foundation
import PairQL

public struct MusicLibrarySnapshot: PairNestable {
  public static let currentSchemaVersion = 3

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

  public var schemaVersion: Int
  public var revision: Int64
  public var generatedAt: Date
  public var albums: [Album]
  public var artists: [Artist]

  public init(
    schemaVersion: Int = Self.currentSchemaVersion,
    revision: Int64,
    generatedAt: Date,
    albums: [Album],
    artists: [Artist],
  ) {
    self.schemaVersion = schemaVersion
    self.revision = revision
    self.generatedAt = generatedAt
    self.albums = albums
    self.artists = artists
  }
}

public struct GetApprovedMusicLibrary_v3: Pair {
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
