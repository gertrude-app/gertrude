import FluentSQL
import Foundation

struct CreateMarketingEmailSends: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE parent.marketing_email_sends (
        id uuid PRIMARY KEY,
        parent_id uuid NOT NULL REFERENCES parent.parents(id) ON DELETE CASCADE,
        campaign text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX idx_marketing_email_sends_parent_campaign
        ON parent.marketing_email_sends (parent_id, campaign);
    """)

    try await sql.execute("""
      CREATE INDEX idx_marketing_email_sends_campaign_created
        ON parent.marketing_email_sends (campaign, created_at DESC);
    """)

    try await sql.execute("""
      INSERT INTO system.short_urls (id, short_id, target, click_count, created_at, deleted_at)
      VALUES (
        '0277e8b0-7ad9-49f8-a52f-41652a31fbba',
        'try-mac',
        'https://gertrude.app/mac',
        0,
        NOW(),
        '2100-01-01 00:00:00+00'
      );
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute(
      "DELETE FROM system.short_urls WHERE id = '0277e8b0-7ad9-49f8-a52f-41652a31fbba';",
    )
    try await sql.execute("DROP TABLE IF EXISTS parent.marketing_email_sends;")
  }
}
