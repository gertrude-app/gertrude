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
    case expired
    case notFound
    case claimed(ChildIOSDeviceData_v2)
    case missingProfile(ChildIOSDeviceData_v2)
    case complete(ChildIOSDeviceData_v2)
  }
}
