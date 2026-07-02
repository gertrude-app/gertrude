import CasePaths
import PairQL

@CasePathable
public enum IOSAppsRoute: PairQLClientRoute {
  case unauthed(UnauthedRoute)
}

public extension IOSAppsRoute {
  static let domain = "ios-apps"
}

public extension IOSAppsRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, IOSAppsRoute> = OneOf {
    Route(AnyCasePath(\IOSAppsRoute.Cases.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}
