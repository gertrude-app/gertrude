import Foundation
import OSLog
import SharingGRDB

extension DatabaseReader {
  func tryRead<T>(_ block: (Database) throws -> [T]) -> [T] {
    withErrorReporting { try self.read { try block($0) } } ?? []
  }

  func tryRead<T>(_ block: (Database) throws -> T) -> T? {
    withErrorReporting { try self.read { try block($0) } }
  }

  func episodeWithShow(_ episodeId: Episode.ID) -> (Episode, Show)? {
    self.tryRead { db in
      try EpisodeWithShow(episodeId: episodeId).fetch(db)
    }.flatMap(\.self)
  }
}

public extension DatabaseWriter {
  func tryWrite<T>(_ updates: (Database) throws -> T) -> T {
    withErrorReporting { try self.write { try updates($0) } }!
  }
}

public func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context
  let database: any DatabaseWriter
  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
    #if DEBUG
      db.trace(options: .profile) {
        logger.debug("\($0.expandedDescription)")
      }
    #endif
    db.add(function: .init("nowPlayingUpdate", argumentCount: 4, pure: false) { args in
      let oldEpisodeId = Int.fromDatabaseValue(args[0]).flatMap { Episode.ID(rawValue: $0) }
      let newEpisodeId = Int.fromDatabaseValue(args[2]).flatMap { Episode.ID(rawValue: $0) }
      let oldState = String.fromDatabaseValue(args[1])
        .flatMap { try? JSON.decode($0, as: NowPlaying.State.self) }
      let newState = String.fromDatabaseValue(args[3])
        .flatMap { try? JSON.decode($0, as: NowPlaying.State.self) }
      Task {
        try await NowPlaying.dispatchUpdate(oldEpisodeId, oldState, newEpisodeId, newState)
      }
      return nil
    })
  }
  switch context {
  case .live:
    let path = URL.documentsDirectory
      .appending(component: "db.sqlite")
      .path()
    logger.info("open \(path)")
    database = try DatabasePool(path: path, configuration: configuration)
  case .preview, .test:
    database = try DatabaseQueue(configuration: configuration)
  }

  var migrator = DatabaseMigrator()
  #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
  #endif
  migrator.registerMigration("pre-release") { db in
    try #sql(
      """
       CREATE TABLE shows (
         id INTEGER PRIMARY KEY NOT NULL,
         name TEXT NOT NULL,
         author TEXT,
         description TEXT,
         feedUrl TEXT NOT NULL UNIQUE,
         websiteUrl TEXT,
         artworkUrl TEXT,
         showArtwork INTEGER NOT NULL CHECK (showArtwork IN (0, 1)),
         iTunesId INTEGER,
         updatedAt TEXT NOT NULL,
         createdAt TEXT NOT NULL
       ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
       CREATE TABLE episodes (
         id INTEGER PRIMARY KEY NOT NULL,
         showId INTEGER NOT NULL,
         episodeNumber INTEGER,
         title TEXT NOT NULL,
         description TEXT,
         websiteUrl TEXT,
         audioUrl TEXT NOT NULL,
         artworkUrl TEXT,
         duration INTEGER,
         sizeInBytes INTEGER NOT NULL,
         audioType TEXT NOT NULL CHECK (audioType IN ('audio/mpeg', 'audio/x-m4a')),
         guid TEXT NOT NULL,
         pubDate TEXT NOT NULL,
         progress REAL NOT NULL DEFAULT 0.0,
         lastPlayedAt TEXT,
         downloadedAt TEXT,
         updatedAt TEXT NOT NULL,
         createdAt TEXT NOT NULL,
         FOREIGN KEY (showId) REFERENCES shows (id) ON DELETE CASCADE
       ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
      CREATE TABLE miscs (
        id TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL,
        rowId INTEGER,
        updatedAt TEXT NOT NULL,
        createdAt TEXT NOT NULL
      ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
      CREATE TABLE events (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        detail TEXT,
        createdAt TEXT NOT NULL
      ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
      CREATE TABLE pinAttempts (
        id INTEGER PRIMARY KEY,
        success INTEGER NOT NULL CHECK (success IN (0, 1)),
        createdAt TEXT NOT NULL
      ) STRICT;
      """
    ).execute(db)
  }
  try migrator.migrate(database)

  try database.write { db in
    try Misc
      .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
      .execute(db)
    try Episode
      .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
      .execute(db)
    try Show
      .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
      .execute(db)

    // ensure nowPlaying is always paused and minimized on app start, before triggers
    try Misc
      .find(id: .nowPlaying)
      .update { $0.value = try! JSON.encode(NowPlaying.State(isPlaying: false, minimized: true)) }
      .execute(db)

    try Misc
      .createTemporaryTrigger(after: .update {
        ($0.value, $0.rowId)
      } forEachRow: {
        #sql("SELECT nowPlayingUpdate(\($0.rowId), \($0.value), \($1.rowId), \($1.value))")
      } when: { old, _ in
        old.id == Misc.ID.nowPlaying
      })
      .execute(db)
    try Misc
      .createTemporaryTrigger(after: .delete {
        #sql("SELECT nowPlayingUpdate(\($0.rowId), \($0.value), NULL, NULL)")
      } when: {
        $0.id == Misc.ID.nowPlaying
      })
      .execute(db)
    try Misc
      .createTemporaryTrigger(after: .insert {
        #sql("SELECT nowPlayingUpdate(NULL, NULL, \($0.rowId), \($0.value))")
      } when: {
        $0.id == Misc.ID.nowPlaying
      })
      .execute(db)
  }

  return database
}

private let logger = Logger(subsystem: "GertiePodcasts", category: "DB")
