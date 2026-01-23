import Foundation
import PairQL

/// in use: v1.7.x - present
public struct LogIOSEvent_v2: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var eventId: String
    public var kind: String
    public var modelIdentifier: String
    public var iOSVersion: String
    public var appVersion: String
    public var vendorId: UUID?
    public var detail: String?

    public init(
      eventId: String,
      kind: String,
      modelIdentifier: String,
      iOSVersion: String,
      appVersion: String,
      vendorId: UUID? = nil,
      detail: String? = nil,
    ) {
      self.eventId = eventId
      self.kind = kind
      self.modelIdentifier = modelIdentifier
      self.iOSVersion = iOSVersion
      self.appVersion = appVersion
      self.vendorId = vendorId
      self.detail = detail
    }
  }

  public typealias Output = Infallible
}
