import Foundation
import PairQL

/// in use: v1.6.4 - present
public struct PinResetEscapeHatch: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var deviceId: UUID?
    public var vendorId: UUID?
    public var modelIdentifier: String
    public var iosVersion: String
    public var appVersion: String
    public var locale: String?

    public init(
      deviceId: UUID?,
      vendorId: UUID?,
      modelIdentifier: String,
      iosVersion: String,
      appVersion: String,
      locale: String? = nil,
    ) {
      self.deviceId = deviceId
      self.vendorId = vendorId
      self.modelIdentifier = modelIdentifier
      self.iosVersion = iosVersion
      self.appVersion = appVersion
      self.locale = locale
    }
  }

  public struct Output: PairOutput {
    public var authorized: Bool

    public init(authorized: Bool) {
      self.authorized = authorized
    }
  }
}
