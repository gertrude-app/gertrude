import CasePaths
import PairQL

@CasePathable
public enum UnauthedRoute: PairRoute {
  case killSwitchCheck(KillSwitchCheck.Input)
  case logEvent(LogAppEvent.Input)
  case reportIdentityTransition(ReportIdentityTransition.Input)
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(AnyCasePath(\UnauthedRoute.Cases.killSwitchCheck)) {
      Operation(KillSwitchCheck.self)
      Body(.json(KillSwitchCheck.Input.self))
    }
    Route(AnyCasePath(\UnauthedRoute.Cases.logEvent)) {
      Operation(LogAppEvent.self)
      Body(.json(LogAppEvent.Input.self))
    }
    Route(AnyCasePath(\UnauthedRoute.Cases.reportIdentityTransition)) {
      Operation(ReportIdentityTransition.self)
      Body(.json(ReportIdentityTransition.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
