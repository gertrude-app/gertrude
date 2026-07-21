import FluentSQL

struct AddParentAccountSiteBeta: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN account_site_beta_enabled boolean NOT NULL DEFAULT false;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN account_site_beta_enabled;
    """)
  }
}
