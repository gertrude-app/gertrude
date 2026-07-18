import PairQL

public enum AuthedRoute: PairRoute {
  case getApprovedMusicLibrary
  case getApprovedMusicLibrary_v2
  case getApprovedMusicLibrary_v3(GetApprovedMusicLibrary_v3.Input)
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
    Route(.case(Self.getApprovedMusicLibrary_v3)) {
      Operation(GetApprovedMusicLibrary_v3.self)
      Body(.json(GetApprovedMusicLibrary_v3.Input.self))
    }
    Route(.case(Self.getApprovedMusicAlbumTracks)) {
      Operation(GetApprovedMusicAlbumTracks.self)
      Body(.json(GetApprovedMusicAlbumTracks.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
