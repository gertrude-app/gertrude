import Foundation
import PairQL

public struct CreateClaimCode: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var deviceId: UUID

    public init(deviceId: UUID) {
      self.deviceId = deviceId
    }
  }

  public struct Output: PairOutput {
    public var code: Int
    public var expiresAt: Date

    public init(code: Int, expiresAt: Date) {
      self.code = code
      self.expiresAt = expiresAt
    }
  }
}
