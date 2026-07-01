import Foundation
import PairQL

public struct CheckBlockerConnectionStatus: Pair {
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
    case expired
    case notFound
    case connected(ChildIOSDeviceData_v2)
  }
}
