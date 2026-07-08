import FluentSQL

struct CreateMusicEvents: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE music_app.events (
        id uuid NOT NULL,
        event_id text NOT NULL,
        level text NOT NULL CHECK (level IN ('debug', 'info', 'warning', 'error', 'critical')),
        domain text,
        detail text,
        device_id uuid,
        model_identifier varchar(32) NOT NULL,
        ios_version varchar(32) NOT NULL,
        app_version varchar(32) NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.events
      ADD CONSTRAINT music_events_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.events
      ADD CONSTRAINT fk_music_events_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      CREATE INDEX idx_music_events_device_created
      ON music_app.events (device_id, created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_music_events_event_device
      ON music_app.events (event_id, device_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE music_app.events;")
  }
}
