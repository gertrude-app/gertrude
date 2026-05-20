import Foundation
import PairQL

public struct GetAccountStatus: Pair {
  public static let auth: ClientAuth = .child

  public typealias Input = NoInput

  public struct Output: PairOutput {
    public var childId: UUID
    public var childName: String
    public var subscription: AmSubscriptionState

    public init(childId: UUID, childName: String, subscription: AmSubscriptionState) {
      self.childId = childId
      self.childName = childName
      self.subscription = subscription
    }
  }
}
