import FluentSQL

struct AppIconUploadProvenance: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macos.mac_apps
      ADD COLUMN icon_uploaded_at timestamptz,
      ADD COLUMN icon_source_app_version text;
    """)

    try await sql.execute("""
      UPDATE macos.mac_apps
      -- stagger refresh to avoid 90 day thundering herd
      SET icon_uploaded_at = CURRENT_TIMESTAMP
        - ((abs(hashtext(bundle_id)::bigint) % (45 * 24 * 60 * 60)) * INTERVAL '1 second')
      WHERE icon IS NOT NULL OR icon_content_hash IS NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macos.mac_apps
      DROP COLUMN IF EXISTS icon_uploaded_at,
      DROP COLUMN IF EXISTS icon_source_app_version;
    """)
  }
}
