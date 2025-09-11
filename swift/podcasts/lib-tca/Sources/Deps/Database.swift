import Foundation
import OSLog
import SharingGRDB

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
         createdAt TEXT NOT NULL
       ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
       CREATE TABLE episodes (
         id INTEGER PRIMARY KEY NOT NULL,
         showId INTEGER NOT NULL,
         title TEXT NOT NULL,
         description TEXT,
         websiteUrl TEXT,
         audioUrl TEXT NOT NULL,
         artworkUrl TEXT,
         duration INTEGER NOT NULL,
         audioType TEXT NOT NULL CHECK (audioType IN ('audio/mpeg', 'audio/x-m4a')),
         guid TEXT NOT NULL,
         pubDate TEXT NOT NULL,
         progress REAL NOT NULL DEFAULT 0.0,
         lastPlayedAt TEXT,
         updatedAt TEXT NOT NULL,
         createdAt TEXT NOT NULL,
         FOREIGN KEY (showId) REFERENCES shows (id) ON DELETE CASCADE
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

  return database
}

private let logger = Logger(subsystem: "GertiePodcasts", category: "DB")
