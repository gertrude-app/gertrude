import PairQL

public struct ConsumePinResetCode: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var code: Int

    public init(code: Int) {
      self.code = code
    }
  }

  public typealias Output = Infallible
}
