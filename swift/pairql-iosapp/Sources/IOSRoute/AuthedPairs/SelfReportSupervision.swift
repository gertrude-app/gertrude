import PairQL

/// deprecated: v1.6.0 - v1.8.1
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
