import FluentSQL

struct AddStripeSubscriptionCancelAt: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD COLUMN cancel_at timestamptz;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP COLUMN IF EXISTS cancel_at;
    """)
  }
}
