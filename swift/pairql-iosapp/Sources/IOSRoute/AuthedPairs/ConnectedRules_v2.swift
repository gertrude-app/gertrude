import Foundation
import GertieIOS
import PairQL

/// in use: v1.7.x - present
public struct ConnectedRules_v2: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var deviceId: UUID
    public var modelIdentifier: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      deviceId: UUID,
      modelIdentifier: String,
      appVersion: String,
      iosVersion: String,
    ) {
      self.deviceId = deviceId
      self.modelIdentifier = modelIdentifier
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public typealias Output = ConnectedRules.Output
}
