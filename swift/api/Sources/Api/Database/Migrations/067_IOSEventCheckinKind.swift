import FluentSQL

struct IOSEventCheckinKind: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT events_kind_check,
      ADD CONSTRAINT events_kind_check CHECK (
        kind = ANY (ARRAY[
          'info', 'onboarding', 'filter', 'error', 'supervision', 'checkin'
        ])
      );
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DELETE FROM iosapp.events WHERE kind = 'checkin';
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT events_kind_check,
      ADD CONSTRAINT events_kind_check CHECK (
        kind = ANY (ARRAY[
          'info', 'onboarding', 'filter', 'error', 'supervision'
        ])
      );
    """)
  }
}
