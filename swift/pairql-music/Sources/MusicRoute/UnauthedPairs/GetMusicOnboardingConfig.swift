import Foundation
import PairQL

public struct GetMusicOnboardingConfig: Pair {
  public static let auth: ClientAuth = .none

  public typealias Input = NoInput

  public struct Output: PairOutput {
    public var explainAccountText: String?
    public var subscriptionRequiredText: String?

    public init(
      explainAccountText: String? = nil,
      subscriptionRequiredText: String? = nil,
    ) {
      self.explainAccountText = explainAccountText
      self.subscriptionRequiredText = subscriptionRequiredText
    }
  }
}
