import CasePaths
import PairQL

@CasePathable
public enum UnauthedRoute: PairRoute {
  case killSwitchCheck(KillSwitchCheck.Input)
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(AnyCasePath(\UnauthedRoute.Cases.killSwitchCheck)) {
      Operation(KillSwitchCheck.self)
      Body(.json(KillSwitchCheck.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
