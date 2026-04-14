import FluentSQL

struct AddKeychainBrandColor: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.keychains
      ADD COLUMN brand_color text;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.keychains
      DROP COLUMN IF EXISTS brand_color;
    """)
  }
}
