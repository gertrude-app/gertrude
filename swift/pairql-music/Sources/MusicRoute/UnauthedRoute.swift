import PairQL

public enum UnauthedRoute: PairRoute {
  case getMusicAppStatus(GetMusicAppStatus.Input)
  case getMusicOnboardingConfig
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.getMusicAppStatus)) {
      Operation(GetMusicAppStatus.self)
      Body(.json(GetMusicAppStatus.Input.self))
    }
    Route(.case(Self.getMusicOnboardingConfig)) {
      Operation(GetMusicOnboardingConfig.self)
    }
  }
  .eraseToAnyParserPrinter()
}
