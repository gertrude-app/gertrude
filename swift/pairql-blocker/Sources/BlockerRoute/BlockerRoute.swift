import Foundation
import PairQL

public enum BlockerRoute: PairRoute {
  case authed(UUID, AuthedRoute)
  case unauthed(UnauthedRoute)
}

extension BlockerRoute: AuthSplitRoute {
  public static let domain = "blocker"
  public typealias Authed = AuthedRoute
  public typealias Unauthed = UnauthedRoute
}

public extension BlockerRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, BlockerRoute> = OneOf {
    Route(.case(Self.authed)) {
      Headers { Field("X-DeviceToken") { UUID.parser() } }
      AuthedRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}
