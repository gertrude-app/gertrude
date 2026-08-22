import Foundation
import PairQL

public enum MusicPlaylistSourceSelection: PairNestable {
  case track(trackId: String, albumId: String)
  case album(albumId: String)
  case artist(artistId: String)
  case playlist(playlistId: UUID)
}

public enum MusicPlaylistDuplicateResolution: String, PairNestable {
  case requestConfirmation
  case addAgain
  case addAll
  case addOnlyNew
}

public enum MusicPlaylistBatchDuplicateResolution: String, PairNestable {
  case requestConfirmation
  case addAll
  case addOnlyNew
}

public struct MusicPlaylistDuplicate: PairNestable {
  public var trackId: String
  public var title: String
  public var existingCount: Int

  public init(trackId: String, title: String, existingCount: Int) {
    self.trackId = trackId
    self.title = title
    self.existingCount = existingCount
  }
}

public enum MusicPlaylistDuplicateConfirmation: PairNestable {
  case track(playlistId: UUID, duplicate: MusicPlaylistDuplicate)
  case album(playlistId: UUID, albumId: String, duplicates: [MusicPlaylistDuplicate])
  case artist(playlistId: UUID, artistId: String, duplicates: [MusicPlaylistDuplicate])
  case playlist(playlistId: UUID, sourcePlaylistId: UUID, duplicates: [MusicPlaylistDuplicate])
}

public struct MusicPlaylistBatchDuplicateConfirmation: PairNestable {
  public var playlistId: UUID
  public var duplicates: [MusicPlaylistDuplicate]

  public init(playlistId: UUID, duplicates: [MusicPlaylistDuplicate]) {
    self.playlistId = playlistId
    self.duplicates = duplicates
  }
}

public enum MusicPlaylistMutationOutput: PairOutput {
  case updated(MusicLibrarySnapshot)
  case duplicateConfirmationRequired(
    snapshot: MusicLibrarySnapshot,
    confirmation: MusicPlaylistDuplicateConfirmation,
  )
  case batchDuplicateConfirmationRequired(
    snapshot: MusicLibrarySnapshot,
    confirmation: MusicPlaylistBatchDuplicateConfirmation,
  )
  case conflict(MusicLibrarySnapshot)
}

public struct CreateMusicPlaylist: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var name: String
    public var source: MusicPlaylistSourceSelection?

    public init(name: String, source: MusicPlaylistSourceSelection? = nil) {
      self.name = name
      self.source = source
    }
  }

  public typealias Output = MusicPlaylistMutationOutput
}

public struct RenameMusicPlaylist: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var playlistId: UUID
    public var expectedRevision: Int64
    public var name: String

    public init(playlistId: UUID, expectedRevision: Int64, name: String) {
      self.playlistId = playlistId
      self.expectedRevision = expectedRevision
      self.name = name
    }
  }

  public typealias Output = MusicPlaylistMutationOutput
}

public struct DeleteMusicPlaylist: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var playlistId: UUID
    public var expectedRevision: Int64

    public init(playlistId: UUID, expectedRevision: Int64) {
      self.playlistId = playlistId
      self.expectedRevision = expectedRevision
    }
  }

  public typealias Output = MusicPlaylistMutationOutput
}

public struct AddToMusicPlaylist: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var playlistId: UUID
    public var source: MusicPlaylistSourceSelection
    public var duplicateResolution: MusicPlaylistDuplicateResolution

    public init(
      playlistId: UUID,
      source: MusicPlaylistSourceSelection,
      duplicateResolution: MusicPlaylistDuplicateResolution = .requestConfirmation,
    ) {
      self.playlistId = playlistId
      self.source = source
      self.duplicateResolution = duplicateResolution
    }
  }

  public typealias Output = MusicPlaylistMutationOutput
}

public struct AddMusicToPlaylist: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var playlistId: UUID
    public var sources: [MusicPlaylistSourceSelection]
    public var duplicateResolution: MusicPlaylistBatchDuplicateResolution

    public init(
      playlistId: UUID,
      sources: [MusicPlaylistSourceSelection],
      duplicateResolution: MusicPlaylistBatchDuplicateResolution = .requestConfirmation,
    ) {
      self.playlistId = playlistId
      self.sources = sources
      self.duplicateResolution = duplicateResolution
    }
  }

  public typealias Output = MusicPlaylistMutationOutput
}

public struct RemoveMusicPlaylistEntry: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var playlistId: UUID
    public var expectedRevision: Int64
    public var entryId: UUID

    public init(playlistId: UUID, expectedRevision: Int64, entryId: UUID) {
      self.playlistId = playlistId
      self.expectedRevision = expectedRevision
      self.entryId = entryId
    }
  }

  public typealias Output = MusicPlaylistMutationOutput
}

public struct ReorderMusicPlaylistEntries: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var playlistId: UUID
    public var expectedRevision: Int64
    public var entryIds: [UUID]

    public init(playlistId: UUID, expectedRevision: Int64, entryIds: [UUID]) {
      self.playlistId = playlistId
      self.expectedRevision = expectedRevision
      self.entryIds = entryIds
    }
  }

  public typealias Output = MusicPlaylistMutationOutput
}
