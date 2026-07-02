import GertieApp
import PairQL

public struct AppUpdateCheck: Pair {
  public static let auth: ClientAuth = .none
  public typealias Input = AppUpdateCheckRequest
  public typealias Output = AppUpdateCheckResponse
}

extension AppUpdateCheckRequest: @retroactive PairInput {}
extension AppUpdateCheckResponse: @retroactive PairOutput {}
