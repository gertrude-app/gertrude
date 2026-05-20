import PairQL

public enum AuthedRoute: PairRoute {
  case getAccountStatus
  case consumePinResetCode(ConsumePinResetCode.Input)
}

public extension AuthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedRoute> = OneOf {
    Route(.case(Self.getAccountStatus)) {
      Operation(GetAccountStatus.self)
    }
    Route(.case(Self.consumePinResetCode)) {
      Operation(ConsumePinResetCode.self)
      Body(.json(ConsumePinResetCode.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
