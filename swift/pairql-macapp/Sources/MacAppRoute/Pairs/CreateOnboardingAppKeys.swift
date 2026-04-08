import Foundation
import PairQL

public struct CreateOnboardingAppKeys: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = [String]
}
