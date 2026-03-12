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

  // context: https://gist.github.com/jaredh159/af45d98eee7f8a33b6b5af945ec23cfc
  public struct Output: PairOutput, Codable, Equatable, Sendable {
    public var blockRules: [BlockRule.Frozen]
    public var webPolicy: WebContentFilterPolicy?

    public init(blockRules: [BlockRule.Frozen], webPolicy: WebContentFilterPolicy?) {
      self.blockRules = blockRules
      self.webPolicy = webPolicy
    }
  }
}
