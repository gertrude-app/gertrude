import Foundation
import GertieIOS
import PairQL

/// in use: v1.7.x - present
public struct ConnectDevice_v2: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var verificationCode: Int
    public var vendorId: UUID
    public var modelIdentifier: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      verificationCode: Int,
      vendorId: UUID,
      modelIdentifier: String,
      appVersion: String,
      iosVersion: String,
    ) {
      self.verificationCode = verificationCode
      self.vendorId = vendorId
      self.modelIdentifier = modelIdentifier
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public typealias Output = ChildIOSDeviceData
}
