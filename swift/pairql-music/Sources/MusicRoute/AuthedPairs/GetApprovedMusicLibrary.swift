import PairQL

public struct GetApprovedMusicLibrary: Pair {
  public static let auth: ClientAuth = .child

  public typealias Input = NoInput

  public struct Output: PairOutput {
    public struct Track: PairNestable {
      public var id: String
      public var title: String
      public var artistName: String
      public var artworkUrl: String?

      public init(
        id: String,
        title: String,
        artistName: String,
        artworkUrl: String?,
      ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkUrl = artworkUrl
      }
    }

    public struct Album: PairNestable {
      public var id: String
      public var title: String
      public var artistName: String
      public var artworkUrl: String?
      public var trackCount: Int?
      public var showsArtwork: Bool
      public var tracks: [Track]

      public init(
        id: String,
        title: String,
        artistName: String,
        artworkUrl: String?,
        trackCount: Int?,
        showsArtwork: Bool,
        tracks: [Track],
      ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkUrl = artworkUrl
        self.trackCount = trackCount
        self.showsArtwork = showsArtwork
        self.tracks = tracks
      }
    }

    public var albums: [Album]

    public init(albums: [Album]) {
      self.albums = albums
    }
  }
}
