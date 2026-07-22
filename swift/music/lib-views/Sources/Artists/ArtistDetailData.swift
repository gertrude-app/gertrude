import Foundation

public struct ArtistDetailData: Identifiable, Equatable, Sendable {
  public let id: String
  public let name: String
  public let artworkUrl: URL?
  public let artworkPalette: ArtworkPalette?
  public let editorialNotes: String?

  public init(
    id: String,
    name: String,
    artworkUrl: URL? = nil,
    artworkPalette: ArtworkPalette? = nil,
    editorialNotes: String? = nil,
  ) {
    self.id = id
    self.name = name
    self.artworkUrl = artworkUrl
    self.artworkPalette = artworkPalette
    self.editorialNotes = editorialNotes
  }
}

public struct ArtistTopSongData: Identifiable, Equatable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let albumTitle: String?
  public let artworkUrl: URL?
  public let duration: String?

  public init(
    id: String,
    title: String,
    artist: String,
    albumTitle: String? = nil,
    artworkUrl: URL? = nil,
    duration: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.albumTitle = albumTitle
    self.artworkUrl = artworkUrl
    self.duration = duration
  }
}

public struct ArtistReleaseData: Identifiable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let artworkUrl: URL?
  public let artworkPalette: ArtworkPalette?
  public let releaseDate: String?
  public let trackCount: Int?
  public let releaseType: String?

  public init(
    id: String,
    title: String,
    artist: String,
    artworkUrl: URL? = nil,
    artworkPalette: ArtworkPalette? = nil,
    releaseDate: String? = nil,
    trackCount: Int? = nil,
    releaseType: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artworkUrl = artworkUrl
    self.artworkPalette = artworkPalette
    self.releaseDate = releaseDate
    self.trackCount = trackCount
    self.releaseType = releaseType
  }
}

public extension ArtistDetailData {
  init(artist: ArtistData) {
    self.init(
      id: artist.id,
      name: artist.name,
      artworkUrl: artist.artworkUrl,
      artworkPalette: artist.artworkPalette,
      editorialNotes: artist.editorialNotes,
    )
  }
}
