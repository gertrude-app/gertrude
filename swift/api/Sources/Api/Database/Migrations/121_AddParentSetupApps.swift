import FluentSQL

struct AddParentSetupApps: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN setup_apps text[];
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN setup_apps;
    """)
  }
}
