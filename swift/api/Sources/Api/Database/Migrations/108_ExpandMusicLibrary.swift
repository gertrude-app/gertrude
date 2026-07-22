import FluentSQL

struct ExpandMusicLibrary: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE music.approved_artists (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        apple_music_artist_id text NOT NULL,
        name text NOT NULL,
        catalog_metadata jsonb,
        created_at timestamp with time zone NOT NULL,
        resolution jsonb,
        resolved_at timestamp with time zone
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

    try await sql.execute("""
      ALTER TABLE music.approved_albums
      ADD COLUMN artwork jsonb,
      ADD COLUMN resolution jsonb,
      ADD COLUMN resolved_at timestamp with time zone;
    """)

    try await sql.execute("""
      CREATE TABLE music.library_snapshots (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        revision bigint NOT NULL,
        payload jsonb NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.library_snapshots
      ADD CONSTRAINT library_snapshots_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.library_snapshots
      ADD CONSTRAINT uq_library_snapshots_child_id UNIQUE (child_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.library_snapshots
      ADD CONSTRAINT fk_library_snapshots_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY music.library_snapshots
      ADD CONSTRAINT ck_library_snapshots_revision_nonnegative CHECK (revision >= 0);
    """)

    try await sql.execute("""
      CREATE TABLE music.playlists (
        id uuid PRIMARY KEY,
        child_id uuid NOT NULL REFERENCES parent.children(id) ON DELETE CASCADE,
        name text NOT NULL,
        revision bigint NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT ck_music_playlists_name
          CHECK (
            name = btrim(name)
            AND char_length(name) BETWEEN 1 AND 100
            AND name !~ E'[\\r\\n]'
          ),
        CONSTRAINT ck_music_playlists_revision CHECK (revision >= 1)
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_music_playlists_child_id
        ON music.playlists (child_id);
    """)

    try await sql.execute("""
      CREATE TABLE music.playlist_entries (
        id uuid PRIMARY KEY,
        playlist_id uuid NOT NULL REFERENCES music.playlists(id) ON DELETE CASCADE,
        position integer NOT NULL,
        apple_music_track_id text NOT NULL,
        preferred_album_id text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT ck_music_playlist_entries_position CHECK (position >= 0),
        CONSTRAINT ck_music_playlist_entries_track_id
          CHECK (char_length(apple_music_track_id) >= 1),
        CONSTRAINT ck_music_playlist_entries_album_id
          CHECK (char_length(preferred_album_id) >= 1),
        CONSTRAINT uq_music_playlist_entries_position UNIQUE (playlist_id, position)
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_music_playlist_entries_playlist_id
        ON music.playlist_entries (playlist_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE music.playlist_entries;")
    try await sql.execute("DROP TABLE music.playlists;")
    try await sql.execute("DROP TABLE music.library_snapshots;")
    try await sql.execute("DROP TABLE music.approved_artists;")
    try await sql.execute("""
      ALTER TABLE music.approved_albums
      DROP COLUMN resolved_at,
      DROP COLUMN resolution,
      DROP COLUMN artwork;
    """)
  }
}
