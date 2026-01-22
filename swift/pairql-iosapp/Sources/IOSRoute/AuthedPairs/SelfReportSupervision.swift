import PairQL

public struct SelfReportSupervision: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var isSupervised: Bool

    public init(isSupervised: Bool) {
      self.isSupervised = isSupervised
    }
  }

  public typealias Output = Infallible
}
