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
  migrator.registerMigration("createPodcast") { db in
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
