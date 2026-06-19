import FluentSQL

struct AddParentDailyReviewEmail: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN time_zone varchar(64),
      ADD COLUMN daily_review_email boolean NOT NULL DEFAULT false,
      ADD COLUMN last_review_email_at timestamp with time zone;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN IF EXISTS last_review_email_at,
      DROP COLUMN IF EXISTS daily_review_email,
      DROP COLUMN IF EXISTS time_zone;
    """)
  }
}
