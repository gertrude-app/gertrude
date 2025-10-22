import Dependencies
import Foundation
import LibViews
import SQLiteData
import Tagged

@Table
struct Episode: Equatable, Hashable {
  typealias ID = Tagged<Self, Int>
  let id: ID
  let showId: Show.ID
  var episodeNumber: Int? = nil
  var title: String
  var description: String?
  var websiteUrl: String?
  var audioUrl: String
  var artworkUrl: String?
  var duration: Int?
  var sizeInBytes: Int
  var audioType: AudioType
  var guid: String
  var isArchived: Bool
  var pubDate: Date
  var progress: Double
  var downloadedAt: Date?
  var lastPlayedAt: Date?
  var completedAt: Date?
  var updatedAt: Date = .init()
  var createdAt: Date
}

enum AudioType: String, Equatable, QueryBindable {
  case mp3 = "audio/mpeg"
  case m4a = "audio/x-m4a"
}

extension Episode.Draft: Equatable {}

extension Episode {
  var downloaded: Bool {
    @Dependency(\.date.now) var now
    guard let downloadedAt = self.downloadedAt else { return false }
    return downloadedAt <= now
  }

  var downloading: Bool {
    @Dependency(\.date.now) var now
    guard let downloadedAt = self.downloadedAt else { return false }
    return downloadedAt > now
  }

  var localAudioUrl: URL {
    let ext = self.audioType == .mp3 ? "mp3" : "m4a"
    return URL.localFilesDir(showId: self.showId)
      .appending(component: "show-\(self.showId)-ep-\(self.id).\(ext)")
  }

  func removeLocalAudioFile() {
    try? FileManager.default.removeItem(at: self.localAudioUrl)
  }

  static var col: TableColumns { Episode.columns }
}

extension Episode {
  struct FeedData: Equatable, Hashable {
    var title: String
    var description: String?
    var websiteUrl: String?
    var audioUrl: String
    var artworkUrl: String?
    var duration: Int?
    var sizeInBytes: Int
    var audioType: AudioType
    var guid: String
    var pubDate: Date
    var episodeNumber: Int?

    func toEpisodeDraft(showId: Show.ID, now: Date) -> Episode.Draft {
      .init(
        showId: showId,
        episodeNumber: self.episodeNumber,
        title: self.title,
        description: self.description,
        websiteUrl: self.websiteUrl,
        audioUrl: self.audioUrl,
        artworkUrl: self.artworkUrl,
        duration: self.duration,
        sizeInBytes: self.sizeInBytes,
        audioType: self.audioType,
        guid: self.guid,
        isArchived: false,
        pubDate: self.pubDate,
        progress: 0.0,
        downloadedAt: nil,
        lastPlayedAt: nil,
        completedAt: nil,
        updatedAt: now,
        createdAt: now,
      )
    }
  }
}

extension EpisodeData {
  init(from episode: Episode, isPlaying: Bool, bufferedProgress: Double?) {
    self.init(
      id: episode.id.rawValue,
      title: episode.title,
      description: episode.description,
      artworkUrl: episode.artworkUrl,
      durationSeconds: episode.duration,
      progress: bufferedProgress ?? episode.progress,
      downloadState: episode.downloaded
        ? .downloaded
        : episode.downloading ? .downloading : .notDownloaded,
      pubDate: episode.pubDate,
      isCompleted: episode.completedAt != nil,
      isPlaying: isPlaying,
      isArchived: episode.isArchived,
    )
  }

  init(nowPlaying: NowPlaying.Data) {
    self.init(
      from: nowPlaying.episode,
      isPlaying: nowPlaying.isPlaying,
      bufferedProgress: nowPlaying.bufferedProgress
    )
  }
}

extension Episode {
  static var mock: Self {
    .init(
      id: 1,
      showId: 1,
      episodeNumber: 1,
      title: "Grace Must Reign",
      audioUrl: "https://example.com/episode1.mp3",
      duration: 3600,
      sizeInBytes: 50_000_000,
      audioType: .mp3,
      guid: "episode-1-guid",
      isArchived: false,
      pubDate: Date(),
      progress: 0.5,
      updatedAt: Date(),
      createdAt: Date(),
    )
  }
}

struct EpisodeWithShow: FetchKeyRequest {
  typealias Value = (Episode, Show)?
  let episodeId: Episode.ID

  func fetch(_ db: Database) throws -> Value {
    try Episode
      .where { $0.id == self.episodeId }
      .join(Show.all) { $0.showId == $1.id }
      .fetchOne(db)
  }
}
