import FluentSQL

struct DeduplicateKeys: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DELETE FROM parent.keys
      WHERE id IN (
        SELECT id FROM (
          SELECT id, ROW_NUMBER() OVER (
            PARTITION BY keychain_id, key
            ORDER BY
              (comment IS NOT NULL AND comment != '') DESC,
              created_at ASC
          ) AS rn
          FROM parent.keys
          WHERE deleted_at IS NULL OR deleted_at > CURRENT_TIMESTAMP
        ) ranked
        WHERE rn > 1
      );
    """)
    try await sql.execute("""
      CREATE UNIQUE INDEX uq_keys_keychain_id_key
      ON parent.keys (keychain_id, key)
      WHERE deleted_at IS NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP INDEX IF EXISTS parent.uq_keys_keychain_id_key;
    """)
  }
}
