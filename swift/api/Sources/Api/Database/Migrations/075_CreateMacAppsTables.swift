import FluentSQL
import Foundation

struct CreateMacAppsTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE macos.mac_apps (
        id uuid PRIMARY KEY,
        bundle_id text NOT NULL UNIQUE,
        name text NOT NULL,
        category text,
        icon bytea,
        icon_content_hash text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE TABLE child.installed_mac_apps (
        id uuid PRIMARY KEY,
        child_id uuid NOT NULL REFERENCES parent.children(id) ON DELETE CASCADE,
        computer_id uuid NOT NULL REFERENCES parent.computers(id) ON DELETE CASCADE,
        mac_app_id uuid NOT NULL REFERENCES macos.mac_apps(id) ON DELETE CASCADE,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_installed_mac_apps_child_computer
        ON child.installed_mac_apps (child_id, computer_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE IF EXISTS child.installed_mac_apps;
    """)
    try await sql.execute("""
      DROP TABLE IF EXISTS macos.mac_apps;
    """)
  }
}
