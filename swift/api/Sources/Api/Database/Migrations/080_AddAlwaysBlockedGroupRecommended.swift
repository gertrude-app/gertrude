import FluentSQL

struct AddAlwaysBlockedGroupRecommended: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macapp.always_blocked_groups
      ADD COLUMN recommended boolean NOT NULL DEFAULT false;
    """)

    try await sql.execute("""
      UPDATE macapp.always_blocked_groups
      SET recommended = true
      WHERE name IN ('Adult content', 'Messages GIF Search', 'Spotlight search');
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macapp.always_blocked_groups
      DROP COLUMN IF EXISTS recommended;
    """)
  }
}
