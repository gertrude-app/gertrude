import PairQL

public enum AuthedRoute: PairRoute {
  case getApprovedMusicLibrary
}

public extension AuthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedRoute> = OneOf {
    Route(.case(Self.getApprovedMusicLibrary)) {
      Operation(GetApprovedMusicLibrary.self)
    }
  }
  .eraseToAnyParserPrinter()
}
