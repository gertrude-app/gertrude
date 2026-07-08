import GertieApp
import PairQL

public struct LogAppEvent: Pair {
  public static let auth: ClientAuth = .none
  public typealias Input = LogEventRequest
  public typealias Output = Infallible
}

extension LogEventRequest: @retroactive PairInput {}
