import FluentSQL

struct PodcastAppTablesAndLegacyAmIap: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE podcast_app.installs (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        app_version varchar NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY podcast_app.installs
      ADD CONSTRAINT installs_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY podcast_app.installs
      ADD CONSTRAINT uq_installs_device_id UNIQUE (device_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY podcast_app.installs
      ADD CONSTRAINT fk_installs_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      CREATE TABLE podcast_app.tokens (
        id uuid NOT NULL,
        value uuid NOT NULL,
        install_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY podcast_app.tokens
      ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY podcast_app.tokens
      ADD CONSTRAINT uq_tokens_value UNIQUE (value);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY podcast_app.tokens
      ADD CONSTRAINT fk_tokens_install_id
      FOREIGN KEY (install_id)
      REFERENCES podcast_app.installs(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      ADD COLUMN legacy_am_iap_paid_at timestamp with time zone;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      DROP COLUMN legacy_am_iap_paid_at;
    """)

    try await sql.execute("DROP TABLE IF EXISTS podcast_app.tokens;")
    try await sql.execute("DROP TABLE IF EXISTS podcast_app.installs;")
  }
}
