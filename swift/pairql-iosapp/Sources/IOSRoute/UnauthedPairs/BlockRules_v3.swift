import Foundation
import GertieIOS
import PairQL

/// in use: v1.8.0 - present
public struct BlockRules_v3: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var deviceId: UUID
    public var appVersion: String
    public var disabledGroups: [UUID]

    public init(deviceId: UUID, appVersion: String, disabledGroups: [UUID]) {
      self.deviceId = deviceId
      self.appVersion = appVersion
      self.disabledGroups = disabledGroups
    }
  }

  public typealias Output = [GertieIOS.BlockRule]
}

extension BlockRule: @retroactive PairOutput {}
