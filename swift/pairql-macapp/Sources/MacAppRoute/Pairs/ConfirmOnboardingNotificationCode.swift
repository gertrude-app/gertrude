import Foundation
import PairQL

public struct ConfirmOnboardingNotificationCode: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var methodId: UUID
    public var code: Int

    public init(methodId: UUID, code: Int) {
      self.methodId = methodId
      self.code = code
    }
  }
}
