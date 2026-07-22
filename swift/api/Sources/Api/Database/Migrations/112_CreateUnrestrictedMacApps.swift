import FluentSQL
import Foundation

struct CreateUnrestrictedMacApps: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE child.unrestricted_mac_apps (
        id uuid PRIMARY KEY,
        child_id uuid NOT NULL REFERENCES parent.children(id) ON DELETE CASCADE,
        scope jsonb NOT NULL,
        schedule jsonb,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_unrestricted_mac_apps_child_id
        ON child.unrestricted_mac_apps (child_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE IF EXISTS child.unrestricted_mac_apps;
    """)
  }
}
