import Foundation
import PairQL

/// in use: v1.6.4 - present
public struct GetPodcastAppConfig: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var deviceId: UUID?
    public var appVersion: String
    public var modelIdentifier: String
    public var iosVersion: String
    public var locale: String

    public init(
      deviceId: UUID?,
      appVersion: String,
      modelIdentifier: String,
      iosVersion: String,
      locale: String,
    ) {
      self.deviceId = deviceId
      self.appVersion = appVersion
      self.modelIdentifier = modelIdentifier
      self.iosVersion = iosVersion
      self.locale = locale
    }
  }

  public struct Output: PairOutput {
    public var explainAccountText: String?
    public var accountPriceText: String?

    public var isEmpty: Bool {
      self == .init()
    }

    public init(
      explainAccountText: String? = nil,
      accountPriceText: String? = nil,
    ) {
      self.explainAccountText = explainAccountText
      self.accountPriceText = accountPriceText
    }
  }
}
