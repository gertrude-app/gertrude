import Foundation
import PairQL

public struct CreateOnboardingKeychain: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = String
}
