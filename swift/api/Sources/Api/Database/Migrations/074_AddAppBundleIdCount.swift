import FluentSQL

struct AddAppBundleIdCount: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macos.app_bundle_ids
      ADD COLUMN count bigint NOT NULL DEFAULT 0;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macos.app_bundle_ids
      DROP COLUMN IF EXISTS count;
    """)
  }
}
