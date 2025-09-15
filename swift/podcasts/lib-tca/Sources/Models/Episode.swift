import Dependencies
import Foundation
import LibViews
import SharingGRDB

@Table
struct Episode: Equatable, Hashable {
  let id: Int
  let showId: Int
  var episodeNumber: Int? = nil
  var title: String
  var description: String?
  var websiteUrl: String?
  var audioUrl: String
  var artworkUrl: String?
  var duration: Int
  var sizeInBytes: Int
  var audioType: AudioType
  var guid: String
  var pubDate: Date
  var progress: Double = 0.0
  var downloadedAt: Date? = nil
  var lastPlayedAt: Date? = nil
  var updatedAt: Date = .init()
  var createdAt: Date
}

enum AudioType: String, Equatable, QueryBindable {
  case mp3 = "audio/mpeg"
  case m4a = "audio/x-m4a"
}

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
    return URL.localShowAudiosDir(showId: self.showId)
      .appending(component: "show-\(self.showId)-ep-\(self.id).\(ext)")
  }
}

extension Episode {
  struct FeedData: Equatable {
    var title: String
    var description: String?
    var websiteUrl: String?
    var audioUrl: String
    var artworkUrl: String?
    var duration: Int
    var sizeInBytes: Int
    var audioType: AudioType
    var guid: String
    var pubDate: Date
    var episodeNumber: Int?

    func toEpisodeDraft(showId: Int) -> Episode.Draft {
      @Dependency(\.date.now) var now
      return .init(
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
        pubDate: self.pubDate,
        createdAt: now,
      )
    }
  }
}

extension EpisodeData {
  init(from episode: Episode, isPlaying: Bool) {
    self.init(
      id: episode.id,
      title: episode.title,
      description: episode.description,
      relativeTime: formatRelativeDate(episode.pubDate),
      duration: formatDuration(episode.duration),
      downloadState: episode.downloaded
        ? .downloaded
        : episode.downloading ? .downloading : .notDownloaded,
      isPlaying: isPlaying
    )
  }

  init(nowPlaying: NowPlaying.Data) {
    self.init(
      id: nowPlaying.episode.id,
      title: nowPlaying.episode.title,
      description: nowPlaying.episode.description,
      relativeTime: formatRelativeDate(nowPlaying.episode.pubDate),
      duration: formatDuration(nowPlaying.episode.duration),
      downloadState: nowPlaying.episode.downloaded
        ? .downloaded
        : nowPlaying.episode.downloading ? .downloading : .notDownloaded,
      isPlaying: nowPlaying.state.isPlaying
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
      pubDate: Date(),
      progress: 0.5,
      updatedAt: Date(),
      createdAt: Date(),
    )
  }
}
