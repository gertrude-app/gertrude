import Foundation
import GertieBlocker
import PairQL

public enum ConnectedRules {
  public struct Output: PairOutput {
    public var blockRules: [BlockRule]
    public var webPolicy: WebContentFilterPolicy?

    public init(blockRules: [BlockRule], webPolicy: WebContentFilterPolicy?) {
      self.blockRules = blockRules
      self.webPolicy = webPolicy
    }
  }
}
