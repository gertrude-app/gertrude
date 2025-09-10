import Foundation

public struct EpisodeData: Identifiable, Sendable, Equatable {
  public let id: Int
  public let title: String
  public let description: String?
  public let relativeTime: String
  public let duration: String
  public let isDownloaded: Bool

  public init(
    id: Int,
    title: String,
    description: String? = nil,
    relativeTime: String,
    duration: String,
    isDownloaded: Bool = false
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.relativeTime = relativeTime
    self.duration = duration
    self.isDownloaded = isDownloaded
  }
}
