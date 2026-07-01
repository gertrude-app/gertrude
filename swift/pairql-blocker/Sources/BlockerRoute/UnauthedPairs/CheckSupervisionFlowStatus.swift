import Foundation
import PairQL

public struct CheckSupervisionFlowStatus: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID
    public var code: Int
    public var appVersion: String?

    public init(vendorId: UUID, code: Int, appVersion: String? = nil) {
      self.vendorId = vendorId
      self.code = code
      self.appVersion = appVersion
    }
  }

  public enum Output: PairOutput {
    case pending
    case expired
    case notFound
    case requiresSubscription(ChildIOSDeviceData_v2)
    case claimed(ChildIOSDeviceData_v2)
    case missingProfile(ChildIOSDeviceData_v2)
    case complete(ChildIOSDeviceData_v2)
  }
}
