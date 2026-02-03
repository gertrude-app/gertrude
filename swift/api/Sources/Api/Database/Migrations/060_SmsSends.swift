import FluentSQL

struct SmsSends: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE system.sms_sends (
        id uuid NOT NULL,
        parent_id uuid NOT NULL,
        trigger varchar(64) NOT NULL,
        country_code varchar(4) NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.sms_sends
      ADD CONSTRAINT sms_sends_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_sms_sends_parent_id ON system.sms_sends (parent_id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_sms_sends_created_at ON system.sms_sends (created_at);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE IF EXISTS system.sms_sends;
    """)
  }
}
