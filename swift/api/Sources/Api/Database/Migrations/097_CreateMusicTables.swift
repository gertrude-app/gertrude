import FluentSQL

struct CreateMusicTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("CREATE SCHEMA music;")

    try await sql.execute("""
      CREATE TABLE music.approved_albums (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        apple_music_album_id text NOT NULL,
        title text NOT NULL,
        artist_name text NOT NULL,
        artwork_url text,
        track_count integer,
        shows_artwork boolean NOT NULL DEFAULT true,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.approved_albums
      ADD CONSTRAINT approved_albums_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.approved_albums
      ADD CONSTRAINT uq_approved_albums_child_apple_music_album
      UNIQUE (child_id, apple_music_album_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.approved_albums
      ADD CONSTRAINT fk_approved_albums_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("CREATE SCHEMA music_app;")

    try await sql.execute("""
      CREATE TABLE music_app.installs (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        app_version varchar NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.installs
      ADD CONSTRAINT installs_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.installs
      ADD CONSTRAINT uq_installs_device_id UNIQUE (device_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.installs
      ADD CONSTRAINT fk_installs_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      CREATE TABLE music_app.tokens (
        id uuid NOT NULL,
        value uuid NOT NULL,
        install_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.tokens
      ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.tokens
      ADD CONSTRAINT uq_tokens_value UNIQUE (value);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.tokens
      ADD CONSTRAINT uq_tokens_install_id UNIQUE (install_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music_app.tokens
      ADD CONSTRAINT fk_tokens_install_id
      FOREIGN KEY (install_id)
      REFERENCES music_app.installs(id) ON DELETE CASCADE;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE music_app.tokens;")
    try await sql.execute("DROP TABLE music_app.installs;")
    try await sql.execute("DROP SCHEMA music_app;")
    try await sql.execute("DROP TABLE music.approved_albums;")
    try await sql.execute("DROP SCHEMA music;")
  }
}
