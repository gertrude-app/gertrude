import FluentSQL

struct AddMarketingEmailSendVariant: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.marketing_email_sends
      ADD COLUMN variant text NOT NULL DEFAULT 'v1';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.marketing_email_sends
      DROP COLUMN IF EXISTS variant;
    """)
  }
}
