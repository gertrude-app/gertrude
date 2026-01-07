import Foundation
import PairQL

/// in use: v1.4.x - present
public struct LogPodcastEvent_v2: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var eventId: String
    public var kind: String
    public var label: String
    public var detail: String?
    public var installId: UUID?
    public var modelIdentifier: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      eventId: String,
      kind: String,
      label: String,
      detail: String? = nil,
      installId: UUID? = nil,
      modelIdentifier: String,
      appVersion: String,
      iosVersion: String,
    ) {
      self.eventId = eventId
      self.kind = kind
      self.label = label
      self.detail = detail
      self.installId = installId
      self.modelIdentifier = modelIdentifier
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public typealias Output = Infallible
}
