import Foundation
import GertieIOS
import PairQL

/// in use: v1.7.x - present
public struct ConnectedRules_v2: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var vendorId: UUID
    public var modelIdentifier: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      vendorId: UUID,
      modelIdentifier: String,
      appVersion: String,
      iosVersion: String,
    ) {
      self.vendorId = vendorId
      self.modelIdentifier = modelIdentifier
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public typealias Output = ConnectedRules.Output
}
