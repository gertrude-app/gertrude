import Foundation
import SQLiteData

extension Episode {
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
          // ... or downloaded more than 90 days ago and never started
          (#sql("\($0.downloadedAt) < \(now - .days(90))") && $0.lastPlayedAt.is(nil))
      }
  }

  static func lastPlayedFor(showId: Show.ID) -> some SelectStatementOf<Episode> {
    Episode
      .where { $0.showId == showId }
      .where { $0.lastPlayedAt.isNot(nil) }
      .where { $0.completedAt.is(nil) }
      .where { $0.isArchived == false }
      .order { $0.lastPlayedAt.desc() }
      .limit(1)
  }

  static func latestUncompletedFor(showId: Show.ID) -> some SelectStatementOf<Episode> {
    Episode
      .where { $0.showId == showId }
      .where { $0.completedAt.is(nil) }
      .where { $0.isArchived == false }
      .order { ($0.pubDate.desc(), $0.episodeNumber.desc()) }
      .limit(1)
  }
}
