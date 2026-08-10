import FluentSQL

struct AddDashAnnouncementCampaign: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.dash_announcements ADD COLUMN campaign varchar(255);
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX idx_dash_announcements_parent_campaign
        ON parent.dash_announcements (parent_id, campaign)
        WHERE campaign IS NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP INDEX IF EXISTS parent.idx_dash_announcements_parent_campaign;
    """)

    try await sql.execute("""
      ALTER TABLE parent.dash_announcements DROP COLUMN campaign;
    """)
  }
}
