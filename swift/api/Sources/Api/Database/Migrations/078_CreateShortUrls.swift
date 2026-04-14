import FluentSQL

struct CreateShortUrls: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE system.short_urls (
        id uuid NOT NULL,
        short_id varchar(16) NOT NULL,
        target text NOT NULL,
        click_count integer NOT NULL DEFAULT 0,
        created_at timestamp with time zone NOT NULL,
        deleted_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.short_urls
      ADD CONSTRAINT short_urls_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX idx_short_urls_short_id ON system.short_urls (short_id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_short_urls_deleted_at ON system.short_urls (deleted_at);
    """)

    try await sql.execute("""
      INSERT INTO system.short_urls (id, short_id, target, click_count, created_at, deleted_at)
      VALUES (
        'de6ebdc8-142a-4056-bd75-b0f0fb439a07',
        'smoke',
        'https://gertrude.app/?smoke-test-short-url=success',
        0,
        NOW(),
        '2100-01-01 00:00:00+00'
      ), (
        'b095cad2-0977-4bdf-a49a-30d2c8059cdc',
        's',
        'https://gertrude.app/security-events',
        0,
        NOW(),
        '2100-01-01 00:00:00+00'
      );
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE IF EXISTS system.short_urls;
    """)
  }
}
