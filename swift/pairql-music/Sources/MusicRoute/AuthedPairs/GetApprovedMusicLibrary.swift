import PairQL

public struct GetApprovedMusicLibrary: Pair {
  public static let auth: ClientAuth = .child

  public typealias Input = NoInput

  public struct Output: PairOutput {
    public struct Album: PairNestable {
      public var id: String
      public var title: String
      public var artistName: String
      public var artworkUrl: String?
      public var trackCount: Int?
      public var showsArtwork: Bool
      public var trackIds: [String]

      public init(
        id: String,
        title: String,
        artistName: String,
        artworkUrl: String?,
        trackCount: Int?,
        showsArtwork: Bool,
        trackIds: [String],
      ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkUrl = artworkUrl
        self.trackCount = trackCount
        self.showsArtwork = showsArtwork
        self.trackIds = trackIds
      }
    }

    public struct Track: PairNestable {
      public var id: String
      public var title: String
      public var artistName: String
      public var albumId: String
      public var albumTitle: String
      public var artworkUrl: String?
      public var showsArtwork: Bool

      public init(
        id: String,
        title: String,
        artistName: String,
        albumId: String,
        albumTitle: String,
        artworkUrl: String?,
        showsArtwork: Bool,
      ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumId = albumId
        self.albumTitle = albumTitle
        self.artworkUrl = artworkUrl
        self.showsArtwork = showsArtwork
      }
    }

    public var albums: [Album]
    public var tracks: [Track]

    public init(albums: [Album], tracks: [Track]) {
      self.albums = albums
      self.tracks = tracks
    }
  }
}
