import Foundation
import PairQL

public struct CheckSupervisionStatus: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID
    public var code: Int

    public init(vendorId: UUID, code: Int) {
      self.vendorId = vendorId
      self.code = code
    }
  }

  public enum Output: PairOutput {
    case pending
    case claimed(ClaimedData)
    case supervised(SupervisedData)
    case complete
    case expired
    case notFound

    public struct ClaimedData: Codable, Equatable, Sendable {
      public var childName: String

      public init(childName: String) {
        self.childName = childName
      }
    }

    public struct SupervisedData: Codable, Equatable, Sendable {
      public var childName: String
      public var deviceToken: UUID
      public var profileUrl: String

      public init(childName: String, deviceToken: UUID, profileUrl: String) {
        self.childName = childName
        self.deviceToken = deviceToken
        self.profileUrl = profileUrl
      }
    }
  }
}
