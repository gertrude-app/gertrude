import FluentSQL

struct AddParentReferrals: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN referral_code varchar(64),
      ADD COLUMN referred_by_parent_id uuid;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD CONSTRAINT chk_parents_referral_code_normalized
      CHECK (
        referral_code IS NULL OR (
          referral_code = upper(referral_code)
          AND referral_code ~ '^[A-Z0-9][A-Z0-9_-]{2,63}$'
        )
      ),
      ADD CONSTRAINT fk_parents_referred_by_parent_id
      FOREIGN KEY (referred_by_parent_id)
      REFERENCES parent.parents(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX uq_parents_referral_code
      ON parent.parents (referral_code)
      WHERE referral_code IS NOT NULL;
    """)

    try await sql.execute("""
      CREATE INDEX idx_parents_referred_by_parent_id
      ON parent.parents (referred_by_parent_id)
      WHERE referred_by_parent_id IS NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP INDEX IF EXISTS parent.idx_parents_referred_by_parent_id;
    """)

    try await sql.execute("""
      DROP INDEX IF EXISTS parent.uq_parents_referral_code;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP CONSTRAINT IF EXISTS fk_parents_referred_by_parent_id,
      DROP CONSTRAINT IF EXISTS chk_parents_referral_code_normalized,
      DROP COLUMN IF EXISTS referred_by_parent_id,
      DROP COLUMN IF EXISTS referral_code;
    """)
  }
}
