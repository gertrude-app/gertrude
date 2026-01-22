import PairQL

public struct MarkSetupComplete: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = NoInput
  public typealias Output = Infallible
}
