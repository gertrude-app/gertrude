import FluentSQL

struct AddClaimLinkOpens: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.claims
      ADD COLUMN link_first_opened_at timestamp with time zone,
      ADD COLUMN link_open_count integer NOT NULL DEFAULT 0;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.claims
      DROP COLUMN IF EXISTS link_first_opened_at,
      DROP COLUMN IF EXISTS link_open_count;
    """)
  }
}
