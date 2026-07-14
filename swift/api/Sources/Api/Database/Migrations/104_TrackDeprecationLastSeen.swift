import FluentSQL

struct TrackDeprecationLastSeen: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.interesting_events
      ADD COLUMN updated_at timestamp with time zone;
    """)

    try await sql.execute("""
      UPDATE system.interesting_events
      SET updated_at = created_at;
    """)

    try await sql.execute("""
      UPDATE system.interesting_events
      SET updated_at = NOW()
      WHERE kind = 'deprecation'
        AND context = 'active';
    """)

    try await sql.execute("""
      ALTER TABLE system.interesting_events
      ALTER COLUMN updated_at SET NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.interesting_events
      DROP COLUMN updated_at;
    """)
  }
}
