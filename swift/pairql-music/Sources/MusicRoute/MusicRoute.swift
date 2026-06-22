import Foundation
import PairQL

public enum MusicRoute: PairRoute {
  case authed(UUID, AuthedRoute)
  case unauthed(UnauthedRoute)
}

extension MusicRoute: AuthSplitRoute {
  public static let domain = "gertrude-music"
  public typealias Authed = AuthedRoute
  public typealias Unauthed = UnauthedRoute
}

public extension MusicRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, MusicRoute> = OneOf {
    Route(.case(Self.authed)) {
      Headers { Field("X-MusicToken") { UUID.parser() } }
      AuthedRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}
