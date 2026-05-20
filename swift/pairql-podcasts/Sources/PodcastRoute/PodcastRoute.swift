import Foundation
import PairQL

public enum PodcastRoute: PairRoute {
  case authed(UUID, AuthedRoute)
  case unauthed(UnauthedRoute)
}

public extension PodcastRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, PodcastRoute> = OneOf {
    Route(.case(Self.authed)) {
      Headers { Field("X-AmToken") { UUID.parser() } }
      AuthedRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}
