import Foundation
import PairQL

public struct CreateOnboardingBlockedApps: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = [String]
}
