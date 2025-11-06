import Foundation

public enum DownloadState: Sendable, Equatable {
  case notDownloaded
  case downloading
  case downloaded
}

public struct EpisodeData: Identifiable, Sendable, Equatable {
  public let id: Int
  public var title: String
  public var description: String?
  public var artworkUrl: String? = nil
  public var durationSeconds: Int?
  public var progress: Double
  public var downloadState: DownloadState
  public var pubDate: Date
  public var isCompleted: Bool
  public var isPlaying: Bool
  public var isArchived: Bool

  public init(
    id: Int,
    title: String,
    description: String? = nil,
    artworkUrl: String? = nil,
    durationSeconds: Int? = nil,
    progress: Double = 0.0,
    downloadState: DownloadState = .notDownloaded,
    pubDate: Date,
    isCompleted: Bool = false,
    isPlaying: Bool = false,
    isArchived: Bool
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.artworkUrl = artworkUrl
    self.durationSeconds = durationSeconds
    self.progress = progress
    self.downloadState = downloadState
    self.pubDate = pubDate
    self.isCompleted = isCompleted
    self.isPlaying = isPlaying
    self.isArchived = isArchived
  }
}

public extension EpisodeData {
  var progressRatio: Double {
    guard let durationSeconds = self.durationSeconds, durationSeconds > 0 else { return 0.0 }
    return self.progress / Double(durationSeconds)
  }

  func pubDateRelative(lang: Lang) -> String {
    formatRelativeDate(self.pubDate, lang: lang)
  }

  func durationShortString(lang: Lang) -> String? {
    self.durationSeconds.map { formatShortDuration($0, lang: lang) }
  }

  func remainingDurationShortString(lang: Lang) -> String? {
    guard let durationSeconds = self.durationSeconds else { return nil }
    let remainingSeconds = max(0, durationSeconds - Int(self.progress))
    return remainingSeconds > 59
      ? formatShortDuration(remainingSeconds, lang: lang)
      : formatRemainingPlayerTime(
        progress: self.progress,
        durationSeconds: durationSeconds,
        withMinus: false
      )
  }

  var currentPlayerTimeString: String {
    formatPlayerTime(Int(self.progress))
  }

  var remainingPlayerTimeString: String {
    formatRemainingPlayerTime(
      progress: self.progress,
      durationSeconds: self.durationSeconds
    )
  }
}
