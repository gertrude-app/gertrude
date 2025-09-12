import Foundation

public enum DownloadState: Sendable, Equatable {
  case notDownloaded
  case downloading
  case downloaded
}

public struct EpisodeData: Identifiable, Sendable, Equatable {
  public let id: Int
  public let title: String
  public let description: String?
  public let relativeTime: String
  public let duration: String
  public let downloadState: DownloadState
  public let isPlaying: Bool

  public init(
    id: Int,
    title: String,
    description: String? = nil,
    relativeTime: String,
    duration: String,
    downloadState: DownloadState = .notDownloaded,
    isPlaying: Bool = false
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.relativeTime = relativeTime
    self.duration = duration
    self.downloadState = downloadState
    self.isPlaying = isPlaying
  }
}
