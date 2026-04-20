import Foundation
import PairQL

public struct SendOnboardingNotificationCode: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var phoneNumber: String

    public init(phoneNumber: String) {
      self.phoneNumber = phoneNumber
    }
  }

  public struct Output: PairOutput {
    public var methodId: UUID

    public init(methodId: UUID) {
      self.methodId = methodId
    }
  }
}
