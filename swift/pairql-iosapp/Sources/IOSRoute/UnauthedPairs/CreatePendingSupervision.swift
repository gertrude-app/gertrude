import Foundation
import PairQL

public struct CreatePendingSupervision: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID
    public var modelIdentifier: String
    public var iosVersion: String
    public var appVersion: String

    public init(vendorId: UUID, modelIdentifier: String, iosVersion: String, appVersion: String) {
      self.vendorId = vendorId
      self.modelIdentifier = modelIdentifier
      self.iosVersion = iosVersion
      self.appVersion = appVersion
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
