import PairQL

public struct MarkSetupComplete: Pair {
  public static let auth: ClientAuth = .child

  public typealias Input = NoInput

  public struct Output: PairOutput {
    public var childName: String

    public init(childName: String) {
      self.childName = childName
    }
  }
}
