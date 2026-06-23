import FluentSQL

struct DashAnnouncementAction: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.dash_announcements ADD COLUMN action jsonb;
    """)
    try await sql.execute("""
      UPDATE parent.dash_announcements
      SET action = jsonb_build_object('label', 'Learn more', 'url', learn_more_url)
      WHERE learn_more_url IS NOT NULL;
    """)
    try await sql.execute("""
      ALTER TABLE parent.dash_announcements DROP COLUMN learn_more_url;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.dash_announcements ADD COLUMN learn_more_url varchar(255);
    """)
    try await sql.execute("""
      UPDATE parent.dash_announcements
      SET learn_more_url = action->>'url'
      WHERE action IS NOT NULL;
    """)
    try await sql.execute("""
      ALTER TABLE parent.dash_announcements DROP COLUMN action;
    """)
  }
}
