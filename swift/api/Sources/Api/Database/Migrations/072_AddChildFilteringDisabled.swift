import FluentSQL

struct AddChildFilteringDisabled: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.children
      ADD COLUMN filtering_disabled boolean NOT NULL DEFAULT false;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.children
      DROP COLUMN IF EXISTS filtering_disabled;
    """)
  }
}
