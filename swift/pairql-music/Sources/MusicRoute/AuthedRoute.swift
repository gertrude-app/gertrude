import PairQL

public enum AuthedRoute: PairRoute {
  case getApprovedMusicLibrary
  case getApprovedMusicLibrary_v2(GetApprovedMusicLibrary_v2.Input)
  case createMusicPlaylist(CreateMusicPlaylist.Input)
  case renameMusicPlaylist(RenameMusicPlaylist.Input)
  case deleteMusicPlaylist(DeleteMusicPlaylist.Input)
  case addSourceToMusicPlaylist(AddSourceToMusicPlaylist.Input)
  case addMusicBatchToPlaylist(AddMusicBatchToPlaylist.Input)
  case removeMusicPlaylistEntry(RemoveMusicPlaylistEntry.Input)
  case reorderMusicPlaylistEntries(ReorderMusicPlaylistEntries.Input)
}

public extension AuthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedRoute> = OneOf {
    Route(.case(Self.getApprovedMusicLibrary)) {
      Operation(GetApprovedMusicLibrary.self)
    }
    Route(.case(Self.getApprovedMusicLibrary_v2)) {
      Operation(GetApprovedMusicLibrary_v2.self)
      Body(.json(GetApprovedMusicLibrary_v2.Input.self))
    }
    Route(.case(Self.createMusicPlaylist)) {
      Operation(CreateMusicPlaylist.self)
      Body(.json(CreateMusicPlaylist.Input.self))
    }
    Route(.case(Self.renameMusicPlaylist)) {
      Operation(RenameMusicPlaylist.self)
      Body(.json(RenameMusicPlaylist.Input.self))
    }
    Route(.case(Self.deleteMusicPlaylist)) {
      Operation(DeleteMusicPlaylist.self)
      Body(.json(DeleteMusicPlaylist.Input.self))
    }
    Route(.case(Self.addSourceToMusicPlaylist)) {
      Operation(AddSourceToMusicPlaylist.self)
      Body(.json(AddSourceToMusicPlaylist.Input.self))
    }
    Route(.case(Self.addMusicBatchToPlaylist)) {
      Operation(AddMusicBatchToPlaylist.self)
      Body(.json(AddMusicBatchToPlaylist.Input.self))
    }
    Route(.case(Self.removeMusicPlaylistEntry)) {
      Operation(RemoveMusicPlaylistEntry.self)
      Body(.json(RemoveMusicPlaylistEntry.Input.self))
    }
    Route(.case(Self.reorderMusicPlaylistEntries)) {
      Operation(ReorderMusicPlaylistEntries.self)
      Body(.json(ReorderMusicPlaylistEntries.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
