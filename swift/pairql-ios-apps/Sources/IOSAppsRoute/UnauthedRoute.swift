import CasePaths
import PairQL

@CasePathable
public enum UnauthedRoute: PairRoute {
  case appUpdateCheck(AppUpdateCheck.Input)
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(AnyCasePath(\UnauthedRoute.Cases.appUpdateCheck)) {
      Operation(AppUpdateCheck.self)
      Body(.json(AppUpdateCheck.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
