import FluentSQL

struct AddCardFingerprint: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      ADD COLUMN card_fingerprint text;
    """)

    try await sql.execute("""
      CREATE INDEX idx_billing_identities_card_fingerprint
        ON parent.billing_identities (card_fingerprint)
        WHERE card_fingerprint IS NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP INDEX IF EXISTS parent.idx_billing_identities_card_fingerprint;")

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      DROP COLUMN IF EXISTS card_fingerprint;
    """)
  }
}
