import FluentSQL

struct CreateMusicApprovedArtists: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE music.approved_artists (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        apple_music_artist_id text NOT NULL,
        name text NOT NULL,
        catalog_metadata jsonb,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.approved_artists
      ADD CONSTRAINT approved_artists_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.approved_artists
      ADD CONSTRAINT uq_approved_artists_child_apple_music_artist
      UNIQUE (child_id, apple_music_artist_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.approved_artists
      ADD CONSTRAINT fk_approved_artists_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE music.approved_artists;")
  }
}
