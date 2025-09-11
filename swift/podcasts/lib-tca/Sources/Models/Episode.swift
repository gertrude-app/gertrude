import Foundation
import LibViews
import SharingGRDB

@Table
struct Episode: Equatable {
  let id: Int
  let showId: Int
  var title: String
  var description: String?
  var websiteUrl: String?
  var audioUrl: String
  var artworkUrl: String?
  var duration: Int
  var audioType: AudioType
  var guid: String
  var pubDate: Date
  var progress: Double = 0.0
  var lastPlayedAt: Date? = nil
  var updatedAt: Date
  var createdAt: Date
}

enum AudioType: String, Equatable, QueryBindable {
  case mp3 = "audio/mpeg"
  case m4a = "audio/x-m4a"
}

extension Episode {
  struct FeedData: Equatable {
    var title: String
    var description: String?
    var websiteUrl: String?
    var audioUrl: String
    var artworkUrl: String?
    var duration: Int
    var audioType: AudioType
    var guid: String
    var pubDate: Date

    func toEpisodeDraft(showId: Int) -> Episode.Draft {
      @Dependency(\.date.now) var now
      return .init(
        showId: showId,
        title: self.title,
        description: self.description,
        websiteUrl: self.websiteUrl,
        audioUrl: self.audioUrl,
        artworkUrl: self.artworkUrl,
        duration: self.duration,
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
      isDownloaded: false // TODO: Implement download tracking
    )
  }
}
