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
  public var relativeTime: String
  public var artworkUrl: String? = nil
  public var duration: String?
  public var durationSeconds: Int?
  public var progress: Double
  public var currentTimeString: String
  public var remainingTimeString: String
  public var downloadState: DownloadState
  public var isPlaying: Bool

  public init(
    id: Int,
    title: String,
    description: String? = nil,
    relativeTime: String,
    artworkUrl: String? = nil,
    duration: String? = nil,
    durationSeconds: Int? = nil,
    progress: Double = 0.0,
    currentTimeString: String = "0:00",
    remainingTimeString: String = "0:00",
    downloadState: DownloadState = .notDownloaded,
    isPlaying: Bool = false
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.relativeTime = relativeTime
    self.artworkUrl = artworkUrl
    self.duration = duration
    self.durationSeconds = durationSeconds
    self.progress = progress
    self.currentTimeString = currentTimeString
    self.remainingTimeString = remainingTimeString
    self.downloadState = downloadState
    self.isPlaying = isPlaying
  }

  public var progressRatio: Double {
    guard let durationSeconds = self.durationSeconds, durationSeconds > 0 else { return 0.0 }
    return self.progress / Double(durationSeconds)
  }
}
