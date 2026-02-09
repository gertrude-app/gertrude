import FluentSQL

struct AddProfileLocked: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN is_profile_locked boolean NOT NULL DEFAULT true;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS is_profile_locked;
    """)
  }
}
