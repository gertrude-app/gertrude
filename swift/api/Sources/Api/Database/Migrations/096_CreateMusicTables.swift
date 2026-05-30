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
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE music.approved_albums;")
    try await sql.execute("DROP SCHEMA music;")
  }
}
