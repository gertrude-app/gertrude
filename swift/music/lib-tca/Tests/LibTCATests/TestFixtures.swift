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

func playbackSnapshot(
  items: [PlaybackItem],
  currentIndex: Int = 0,
  playStatus: PlaybackFeature.PlayStatus = .playing,
  progress: PlaybackProgress = .zero,
) -> PlaybackSnapshot {
  let entries = items.enumerated().map { index, item in
    PlaybackQueueEntry(id: "entry-\(index)", item: item)
  }
  return PlaybackSnapshot(
    entries: entries,
    currentEntryID: entries.indices.contains(currentIndex) ? entries[currentIndex].id : nil,
    playStatus: playStatus,
    progress: progress,
  )
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

extension PlaybackCheckpoint {
  static let mock = Self(
    songIDs: ["track-1", "track-2"],
    currentIndex: 1,
    elapsedTime: 42,
    durationFallback: 180,
    sourceAlbumHints: [
      .init(songID: "track-1", albumID: "album-1"),
    ],
  )

  static let otherMock = Self(
    songIDs: ["other-track"],
    currentIndex: 0,
    elapsedTime: 12,
    durationFallback: 120,
  )
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
