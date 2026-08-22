import PairQL

public enum UnauthedRoute: PairRoute {
  case crossPromos(CrossPromos.Input)
  case getMusicAppStatus(GetMusicAppStatus.Input)
  case getMusicAppStatus_v2(GetMusicAppStatus_v2.Input)
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.crossPromos)) {
      Operation(CrossPromos.self)
      Body(.json(CrossPromos.Input.self))
    }
    Route(.case(Self.getMusicAppStatus)) {
      Operation(GetMusicAppStatus.self)
      Body(.json(GetMusicAppStatus.Input.self))
    }
    Route(.case(Self.getMusicAppStatus_v2)) {
      Operation(GetMusicAppStatus_v2.self)
      Body(.json(GetMusicAppStatus_v2.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
