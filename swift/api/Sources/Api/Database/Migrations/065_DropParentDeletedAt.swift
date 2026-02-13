import FluentSQL

struct DropParentDeletedAt: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN IF EXISTS deleted_at;
    """)

    try await sql.execute("""
      UPDATE parent.subscriptions
      SET status_expires_at = '4001-01-01T00:00:00Z'
      WHERE billing_status = 'unpaid';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
    """)
  }
}
