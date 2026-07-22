import FluentSQL

struct AppStoreMusicApp: GertieMigration {
  // constraint names are postgres-generated, from migration 052 `AppStoreReviews`
  let appColumns = [
    ("appstore.reviews", "reviews_app_check"),
    ("appstore.rating_snapshots", "rating_snapshots_app_check"),
    ("appstore.rating_events", "rating_events_app_check"),
  ]

  func up(sql: SQLDatabase) async throws {
    for (table, constraint) in self.appColumns {
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        DROP CONSTRAINT \(unsafeRaw: constraint);
      """)
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ADD CONSTRAINT \(unsafeRaw: constraint)
        CHECK (app IN ('blocker', 'podcasts', 'music'));
      """)
    }
  }

  func down(sql: SQLDatabase) async throws {
    for (table, constraint) in self.appColumns {
      try await sql.execute("""
        DELETE FROM \(unsafeRaw: table) WHERE app = 'music';
      """)
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        DROP CONSTRAINT \(unsafeRaw: constraint);
      """)
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ADD CONSTRAINT \(unsafeRaw: constraint)
        CHECK (app IN ('blocker', 'podcasts'));
      """)
    }
  }
}
