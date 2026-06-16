import Foundation
import PairQL

public struct GetTrialStatus: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var deviceId: UUID
    public var modelIdentifier: String
    public var iosVersion: String
    public var appVersion: String

    public init(
      deviceId: UUID,
      modelIdentifier: String,
      iosVersion: String,
      appVersion: String,
    ) {
      self.deviceId = deviceId
      self.modelIdentifier = modelIdentifier
      self.iosVersion = iosVersion
      self.appVersion = appVersion
    }
  }

  public enum Output: PairOutput {
    case trial(expiresAt: Date)
    case trialExpired(since: Date)
    case legacyGrandfathered(accessEndsAt: Date, showMigrationNag: Bool, migrationUrl: URL?)
    case connected(
      token: UUID,
      childId: UUID,
      childName: String,
      subscription: AmSubscriptionState,
    )
  }
}
