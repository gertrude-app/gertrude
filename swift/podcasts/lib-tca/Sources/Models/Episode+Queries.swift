import Foundation
import SQLiteData

extension Episode {
  static var incompleteAndUnarchived: Where<Self> {
    Episode
      .where { $0.completedAt.is(nil) }
      .where { $0.isArchived.eq(false) }
  }

  static func whereDownloadCanBeDeleted(
    nowPlaying: Episode.ID?,
    now: Date,
  ) throws -> Where<Episode> {
    Episode
      .where {
        $0.downloadedAt.isNot(nil)
      }
      .where {
        if let episodeId = nowPlaying {
          $0.id.neq(episodeId)
        }
      }
      .where {
        // finished listening more than 7 days ago
        #sql("\($0.completedAt) < \(now - .days(7))") ||
          // ... or downloaded more than 45 days ago and never started
          (#sql("\($0.downloadedAt) < \(now - .days(45))") && $0.lastPlayedAt.is(nil)) ||
          // ... or downloaded more than 60 days ago and last played more than 30 days ago
          (#sql("\($0.downloadedAt) < \(now - .days(60))") &&
            #sql("\($0.lastPlayedAt) < \(now - .days(30))") && $0.completedAt.is(nil))
      }
  }

  static func lastPlayedFor(showId: Show.ID) -> some SelectStatementOf<Episode> {
    Episode.incompleteAndUnarchived
      .where { $0.showId.eq(showId) }
      .where { $0.lastPlayedAt.isNot(nil) }
      .order { $0.lastPlayedAt.desc() }
      .limit(1)
  }

  static func latestUncompletedFor(showId: Show.ID) -> some SelectStatementOf<Episode> {
    Episode.incompleteAndUnarchived
      .where { $0.showId.eq(showId) }
      .order { ($0.pubDate.desc(), $0.episodeNumber.desc()) }
      .limit(1)
  }
}
