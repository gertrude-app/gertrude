import Foundation
import LibViews
import SharingGRDB

@Table
struct Episode: Equatable {
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
  var updatedAt: Date
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
        updatedAt: now,
        createdAt: now,
      )
    }
  }
}

extension EpisodeData {
  init(from episode: Episode) {
    self.init(
      id: episode.id,
      title: episode.title,
      description: episode.description,
      relativeTime: formatRelativeDate(episode.pubDate),
      duration: formatDuration(episode.duration),
      downloadState: episode.downloaded
        ? .downloaded
        : episode.downloading ? .downloading : .notDownloaded,
      isPlaying: false // TODO: Implement playing state tracking
    )
  }
}
