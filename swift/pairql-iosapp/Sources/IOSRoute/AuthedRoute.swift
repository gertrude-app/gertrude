import PairQL

public enum AuthedRoute: PairRoute {
  case connectedRules_v2(ConnectedRules_v2.Input)
  case createSuspendFilterRequest(CreateSuspendFilterRequest.Input)
  case markSupervisionProfileInstalled
  case pollFilterSuspensionDecision(PollFilterSuspensionDecision.Input)
  case selfReportSupervision(SelfReportSupervision.Input)
}

public extension AuthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedRoute> = OneOf {
    Route(.case(Self.connectedRules_v2)) {
      Operation(ConnectedRules_v2.self)
      Body(.json(ConnectedRules_v2.Input.self))
    }
    Route(.case(Self.createSuspendFilterRequest)) {
      Operation(CreateSuspendFilterRequest.self)
      Body(.json(CreateSuspendFilterRequest.Input.self))
    }
    Route(.case(Self.markSupervisionProfileInstalled)) {
      Operation(MarkSupervisionProfileInstalled.self)
    }
    Route(.case(Self.pollFilterSuspensionDecision)) {
      Operation(PollFilterSuspensionDecision.self)
      Body(.json(PollFilterSuspensionDecision.Input.self))
    }
    Route(.case(Self.selfReportSupervision)) {
      Operation(SelfReportSupervision.self)
      Body(.json(SelfReportSupervision.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
