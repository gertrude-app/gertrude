import Foundation
import PairQL

public enum MacAppRoute: PairRoute {
  case userAuthed(UUID, AuthedUserRoute)
  case unauthed(UnauthedRoute)
}

extension MacAppRoute: AuthSplitRoute {
  public static let domain = "macos-app"
  public typealias Authed = AuthedUserRoute
  public typealias Unauthed = UnauthedRoute
  public static func authed(_ token: UUID, _ route: AuthedUserRoute) -> Self {
    .userAuthed(token, route)
  }
}

public extension MacAppRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, MacAppRoute> = OneOf {
    Route(.case(Self.userAuthed)) {
      Headers { Field("X-UserToken") { UUID.parser() } }
      AuthedUserRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}
