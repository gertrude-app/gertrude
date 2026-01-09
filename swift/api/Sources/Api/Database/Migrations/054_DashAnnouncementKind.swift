import FluentSQL

struct DashAnnouncementKind: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.dash_announcements
      ADD COLUMN kind varchar(255) NOT NULL DEFAULT 'news'
      CHECK (kind IN ('news', 'warning'));
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.dash_announcements
      DROP COLUMN kind;
    """)
  }
}
