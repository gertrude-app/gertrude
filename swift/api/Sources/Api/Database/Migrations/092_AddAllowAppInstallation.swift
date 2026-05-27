import FluentSQL

struct AddAllowAppInstallation: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.installs
      ADD COLUMN allow_app_installation boolean NOT NULL DEFAULT true;
    """)
    // preserve previously hardcoded workaround now removed from ProfileDownload.swift
    try await sql.execute("""
      UPDATE blocker_app.installs
      SET allow_app_installation = false
      WHERE device_id = 'ed25c68a-2dba-4854-b3bd-efe0d8523e6f';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.installs
      DROP COLUMN IF EXISTS allow_app_installation;
    """)
  }
}
