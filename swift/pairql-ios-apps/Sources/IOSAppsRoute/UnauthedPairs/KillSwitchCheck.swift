import GertieApp
import PairQL

public struct KillSwitchCheck: Pair {
  public static let auth: ClientAuth = .none
  public typealias Input = KillSwitchCheckRequest
  public typealias Output = KillSwitchCheckResponse
}

extension KillSwitchCheckRequest: @retroactive PairInput {}
extension KillSwitchCheckResponse: @retroactive PairOutput {}
