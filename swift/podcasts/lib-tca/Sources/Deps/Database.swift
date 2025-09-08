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
         feedURL TEXT NOT NULL,
         artworkURL TEXT,
         showEpisodeArtwork INTEGER NOT NULL DEFAULT 0
           CHECK (showEpisodeArtwork IN (0, 1)),
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
        created_at TEXT NOT NULL
      ) STRICT;
      """
    ).execute(db)
  }
  try migrator.migrate(database)

  return database
}

private let logger = Logger(subsystem: "GertiePodcasts", category: "DB")
