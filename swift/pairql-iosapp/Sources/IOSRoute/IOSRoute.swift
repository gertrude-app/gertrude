import Foundation
import PairQL

public enum IOSRoute: PairRoute {
  case authed(UUID, AuthedRoute)
  case unauthed(UnauthedRoute)
}

extension IOSRoute: AuthSplitRoute {
  public static let domain = "ios-app"
  public typealias Authed = AuthedRoute
  public typealias Unauthed = UnauthedRoute
}

public extension IOSRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, IOSRoute> = OneOf {
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
