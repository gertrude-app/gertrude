import Foundation
import PairQL

public struct GetMusicAppStatus_v2: Pair {
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

  public enum Entitlement: PairNestable {
    case active
    case unavailable
  }

  public enum Output: PairOutput {
    case unclaimed(code: Int, expiresAt: Date)
    case claimed(token: UUID, childId: UUID, childName: String, entitlement: Entitlement)
  }
}
