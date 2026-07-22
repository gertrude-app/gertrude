import Foundation

public struct PlaylistData: Equatable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let entries: [PlaylistEntryData]

  public init(
    id: String,
    name: String,
    entries: [PlaylistEntryData] = [],
  ) {
    self.id = id
    self.name = name
    self.entries = entries
  }

  public var trackCount: Int {
    self.entries.count
  }

  public var artworkUrls: [URL] {
    var seen = Set<URL>()
    return self.entries.compactMap(\.track.artworkUrl).filter {
      seen.insert($0).inserted
    }
  }
}

public struct PlaylistEntryData: Equatable, Identifiable, Sendable {
  public let id: String
  public let track: TrackData

  public init(id: String, track: TrackData) {
    self.id = id
    self.track = track
  }
}

#if DEBUG
  extension PlaylistData {
    static let previewRoadTrip = PlaylistData(
      id: "preview-playlist",
      name: "Road Trip",
      entries: [
        .init(
          id: "entry-1",
          track: .init(
            id: "song-1",
            title: "On the Road",
            artist: "The Travelers",
            artworkUrl: PreviewMusicData.storiesArtworkURL,
          ),
        ),
        .init(
          id: "entry-2",
          track: .init(
            id: "song-2",
            title: "Open Sky",
            artist: "Northbound",
            artworkUrl: PreviewMusicData.brewedArtworkURL,
          ),
        ),
        .init(
          id: "entry-3",
          track: .init(
            id: "song-1",
            title: "On the Road",
            artist: "The Travelers",
            artworkUrl: PreviewMusicData.ruleOf3ArtworkURL,
          ),
        ),
        .init(
          id: "entry-4",
          track: .init(
            id: "song-4",
            title: "Home by Morning",
            artist: "Northbound",
            artworkUrl: PreviewMusicData.frifotArtworkURL,
          ),
        ),
      ],
    )
  }
#endif
