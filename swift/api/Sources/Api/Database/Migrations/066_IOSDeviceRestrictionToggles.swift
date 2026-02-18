import FluentSQL

struct IOSDeviceRestrictionToggles: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN allow_app_removal boolean NOT NULL DEFAULT false,
      ADD COLUMN allow_erase_content_and_settings boolean NOT NULL DEFAULT false;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS allow_app_removal,
      DROP COLUMN IF EXISTS allow_erase_content_and_settings;
    """)
  }
}
