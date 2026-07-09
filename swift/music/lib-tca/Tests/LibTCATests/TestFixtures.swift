import Dependencies
import Foundation

@testable import LibTCA

struct TestError: Error {}

let childId = UUID(1)
let otherChildId = UUID(2)

let cachedApprovedMusicLibrary = ApprovedMusicLibrary(
  albums: [
    .init(
      id: "cached-album",
      title: "Cached Album",
      artistName: "Cached Artist",
      tracks: [
        .init(
          id: "cached-track",
          title: "Cached Track",
          artistName: "Cached Artist",
        ),
      ],
    ),
  ],
  artists: [
    .init(
      id: "cached-artist",
      name: "Cached Artist",
    ),
  ],
)

func playbackItem(_ id: ApprovedTrack.ID) -> PlaybackItem {
  PlaybackItem(
    id: id,
    title: "Track \(id.rawValue)",
    artistName: "Artist",
    artworkURL: nil,
  )
}

func playbackItems(album: ApprovedAlbum) -> [PlaybackItem] {
  album.tracks.map { PlaybackItem(
    track: $0,
    artworkURL: album.artworkURL,
    albumID: album.id,
  ) }
}

func temporaryDirectory(named name: String, fileID: String = #fileID) throws -> URL {
  let suiteName = URL(fileURLWithPath: fileID).deletingPathExtension().lastPathComponent
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    suiteName,
    isDirectory: true,
  )
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  let directory = root.appendingPathComponent(name, isDirectory: true)
  try? FileManager.default.removeItem(at: directory)
  return directory
}

extension CachedPlaybackSession {
  static let mock = Self(
    items: [
      PlaybackItem(
        id: "track-1",
        title: "Track 1",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/artwork.jpg"),
        albumID: "album-1",
      ),
      PlaybackItem(
        id: "track-2",
        title: "Track 2",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/artwork.jpg"),
        albumID: "album-1",
      ),
    ],
    currentIndex: 1,
    progress: .init(elapsedTime: 42, duration: 180),
  )

  static let otherMock = Self(
    items: [
      PlaybackItem(
        id: "other-track",
        title: "Other Track",
        artistName: "Other Artist",
        artworkURL: nil,
      ),
    ],
    currentIndex: 0,
    progress: .init(elapsedTime: 12, duration: 120),
  )
}
