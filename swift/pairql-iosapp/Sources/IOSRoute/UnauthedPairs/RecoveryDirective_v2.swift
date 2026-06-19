import Foundation
import GertieBlocker
import PairQL

/// in use: v1.7.x - present
public struct RecoveryDirective_v2: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID?
    public var modelIdentifier: String
    public var iOSVersion: String
    public var locale: String?
    public var version: String?

    public init(
      vendorId: UUID?,
      modelIdentifier: String,
      iOSVersion: String,
      locale: String? = nil,
      version: String? = nil,
    ) {
      self.vendorId = vendorId
      self.modelIdentifier = modelIdentifier
      self.iOSVersion = iOSVersion
      self.locale = locale
      self.version = version
    }
  }

  public typealias Output = RecoveryDirective.Output
}
