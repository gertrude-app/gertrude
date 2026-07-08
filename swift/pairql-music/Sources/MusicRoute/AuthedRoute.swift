import PairQL

public enum AuthedRoute: PairRoute {
  case getApprovedMusicLibrary
  case getApprovedMusicLibrary_v2
  case getApprovedMusicAlbumTracks(GetApprovedMusicAlbumTracks.Input)
}

public extension AuthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedRoute> = OneOf {
    Route(.case(Self.getApprovedMusicLibrary)) {
      Operation(GetApprovedMusicLibrary.self)
    }
    Route(.case(Self.getApprovedMusicLibrary_v2)) {
      Operation(GetApprovedMusicLibrary_v2.self)
    }
    Route(.case(Self.getApprovedMusicAlbumTracks)) {
      Operation(GetApprovedMusicAlbumTracks.self)
      Body(.json(GetApprovedMusicAlbumTracks.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
