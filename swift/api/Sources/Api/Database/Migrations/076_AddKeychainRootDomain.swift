import FluentSQL

struct AddKeychainRootDomain: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.keychains
      ADD COLUMN root_domain text;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.keychains
      DROP COLUMN IF EXISTS root_domain;
    """)
  }
}
