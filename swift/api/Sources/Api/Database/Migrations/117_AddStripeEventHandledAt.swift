import FluentSQL

struct AddStripeEventHandledAt: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.stripe_events
      ADD COLUMN handled_at timestamptz;
    """)

    try await sql.execute("""
      UPDATE system.stripe_events
      SET handled_at = created_at;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.stripe_events
      DROP COLUMN IF EXISTS handled_at;
    """)
  }
}
