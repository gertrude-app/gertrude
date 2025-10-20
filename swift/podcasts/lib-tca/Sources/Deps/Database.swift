import Foundation
import OSLog
import SQLiteData

extension DatabaseReader {
  func tryRead<T>(_ block: (Database) throws -> [T]) -> [T] {
    withErrorReporting { try self.read { try block($0) } } ?? []
  }

  func tryRead<T>(_ block: (Database) throws -> T?) -> T? {
    if let value = withErrorReporting(catching: { try self.read { try block($0) } }) {
      value
    } else {
      nil
    }
  }

  func episodeWithShow(_ episodeId: Episode.ID) -> (episode: Episode, show: Show)? {
    self.tryRead { db in
      try EpisodeWithShow(episodeId: episodeId).fetch(db)
    }.flatMap(\.self)
  }

  func show(id: Show.ID) -> Show? {
    self.tryRead { db in
      try Show.find(id).fetchOne(db)
    }
  }

  func nowPlaying() -> NowPlaying.Data? {
    self.tryRead { db in
      try NowPlaying().fetch(db)
    }
  }

  func subscription() -> Subscription {
    self.tryRead { db in
      try CurrentSubscription().fetch(db)
    } ?? .fallback
  }

  func record(id: Record.ID) -> Record? {
    self.tryRead { db in
      try Record.find(id: id).fetchOne(db)
    }
  }
}

extension DatabaseWriter {
  func tryWrite<T>(_ updates: (Database) throws -> T) -> T {
    withErrorReporting { try self.write { try updates($0) } }!
  }

  func insertEvent(
    kind: EventKind.Db,
    label: String,
    detail: String? = nil,
    apiId: String? = nil
  ) {
    self.tryWrite { db in
      try Event
        .insert { Event.Draft(kind: kind.rawValue, label: label, detail: detail, apiId: apiId) }
        .execute(db)
    }
  }

  func insertRecord(id: Record.ID, value: String = "", detail: String? = nil) {
    self.tryWrite { db in
      try Record
        .insert { Record.Draft(id: id, value: value, detail: detail) }
        .execute(db)
    }
  }
}

public func appDatabase(
  beforeTriggersHook: ((Database) throws -> Void)? = nil
) throws -> any DatabaseWriter {
  @Dependency(\.context) var context
  let database: any DatabaseWriter
  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
    #if DEBUG
      db.trace(options: .profile) { logger.debug("\($0.expandedDescription)") }
    #endif
    db.add(function: .init("nowPlayingUpdate", argumentCount: 4, pure: false) { args in
      let oldEpisodeId = Int.fromDatabaseValue(args[0]).flatMap { Episode.ID(rawValue: $0) }
      let newEpisodeId = Int.fromDatabaseValue(args[2]).flatMap { Episode.ID(rawValue: $0) }
      let oldWasPlaying = Bool.fromDatabaseValue(args[1])
      let newIsPlaying = Bool.fromDatabaseValue(args[3])
      Task {
        try await NowPlaying.dispatchUpdate(oldEpisodeId, oldWasPlaying, newEpisodeId, newIsPlaying)
      }
      return nil
    })
  }
  switch context {
  case .live:
    replaceLocalDbWithDownloadedDb()
    let path = URL.localDb.path
    logger.info("open \(path)")
    database = try DatabasePool(path: path, configuration: configuration)
  case .preview, .test:
    database = try DatabaseQueue(configuration: configuration)
  }

  var migrator = DatabaseMigrator()
  #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
  #endif

  migrator.registerMigration("pre-release") {
    try Migrations.preRelease($0)
  }
  migrator.registerMigration("m_2025-10-07") {
    try Migrations.m2025_10_07($0)
  }
  migrator.registerMigration("m_2025-10-08") {
    try Migrations.m2025_10_08($0)
  }
  migrator.registerMigration("m_2025-10-13") {
    try Migrations.m2025_10_13($0)
  }
  migrator.registerMigration("m_2025-10-20") {
    try Migrations.m2025_10_20($0)
  }
  try migrator.migrate(database)

  try database.write { db in
    try alwaysBeforeTriggersCreated(db)
    try beforeTriggersHook?(db)
    try createDatabaseTriggers(db)
  }

  return database
}

func alwaysBeforeTriggersCreated(_ db: Database) throws {
  // initialize now playing before triggers
  try NowPlayingModel
    .update {
      $0.isPlaying = false
      $0.minimized = true
    }
    .execute(db)

  // clean up stuck downloads
  let stuckDownloads = try Episode
    .where { $0.downloadedAt > #sql("datetime('now', '+100 years')") }
    .delete()
    .returning(\.self)
    .fetchAll(db)
  stuckDownloads.forEach { $0.removeLocalAudioFile() }

  // stale feed updates lock
  try Record
    .find(id: .feedUpdatesLock)
    .delete()
    .execute(db)
}

private let logger = Logger(subsystem: "GertiePodcasts", category: "DB")

extension DependencyValues {
  var db: any DatabaseWriter {
    get { self[keyPath: \.defaultDatabase] }
    set { self[keyPath: \.defaultDatabase] = newValue }
  }
}

extension URL {
  static var localDb: URL {
    documentsDirectory.appending(component: "db.sqlite")
  }

  static var localDbWal: URL {
    documentsDirectory.appending(component: "db.sqlite-wal")
  }

  static var localDbShm: URL {
    documentsDirectory.appending(component: "db.sqlite-shm")
  }

  static var tempDb: URL {
    documentsDirectory.appending(component: "tmp.sqlite")
  }
}

func replaceLocalDbWithDownloadedDb() {
  if FileManager.default.fileExists(atPath: URL.tempDb.path) {
    try? FileManager.default.removeItem(at: .localDbWal)
    try? FileManager.default.removeItem(at: .localDbShm)
    _ = try? FileManager.default.replaceItemAt(.localDb, withItemAt: .tempDb)
    log(.info("3c4e2f29"), "replaced local db w/ downloaded")
  }
}
