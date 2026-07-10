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

public struct GetApprovedMusicLibrary_v2: Pair {
  public static let auth: ClientAuth = .child

  public typealias Input = NoInput

  public struct Output: PairOutput {
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

      public init(
        id: String,
        title: String,
        artistName: String,
        artworkUrl: String?,
        artwork: MusicArtwork? = nil,
        trackCount: Int?,
        releaseDate: String? = nil,
        releaseType: String? = nil,
        showsArtwork: Bool,
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
      }
    }

    public struct Artist: PairNestable {
      public struct TopSong: PairNestable {
        public var id: String
        public var title: String
        public var artistName: String
        public var albumTitle: String?
        public var artworkUrl: String?
        public var durationInMillis: Int?

        public init(
          id: String,
          title: String,
          artistName: String,
          albumTitle: String? = nil,
          artworkUrl: String? = nil,
          durationInMillis: Int? = nil,
        ) {
          self.id = id
          self.title = title
          self.artistName = artistName
          self.albumTitle = albumTitle
          self.artworkUrl = artworkUrl
          self.durationInMillis = durationInMillis
        }
      }

      public var id: String
      public var name: String
      public var catalogMetadata: MusicCatalogMetadata?
      public var releaseAlbumIds: [String]?
      public var topSongs: [TopSong]?

      public init(
        id: String,
        name: String,
        catalogMetadata: MusicCatalogMetadata? = nil,
        releaseAlbumIds: [String]? = nil,
        topSongs: [TopSong]? = nil,
      ) {
        self.id = id
        self.name = name
        self.catalogMetadata = catalogMetadata
        self.releaseAlbumIds = releaseAlbumIds
        self.topSongs = topSongs
      }
    }

    public var albums: [Album]
    public var artists: [Artist]

    public init(
      albums: [Album],
      artists: [Artist],
    ) {
      self.albums = albums
      self.artists = artists
    }
  }
}
