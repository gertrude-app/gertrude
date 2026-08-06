import FluentSQL

struct AddMusicTrackGrants: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE music.approved_tracks (
        id uuid PRIMARY KEY,
        child_id uuid NOT NULL REFERENCES parent.children(id) ON DELETE CASCADE,
        apple_music_track_id text NOT NULL,
        preferred_album_id text NOT NULL,
        resolution jsonb NOT NULL,
        shows_artwork boolean NOT NULL DEFAULT true,
        resolved_at timestamptz NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_approved_tracks_child_apple_music_track
          UNIQUE (child_id, apple_music_track_id),
        CONSTRAINT ck_approved_tracks_apple_music_track_id
          CHECK (char_length(apple_music_track_id) >= 1),
        CONSTRAINT ck_approved_tracks_preferred_album_id
          CHECK (char_length(preferred_album_id) >= 1)
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_approved_tracks_child_preferred_album
        ON music.approved_tracks (child_id, preferred_album_id);
    """)

    try await sql.execute("""
      ALTER TABLE music.approved_albums
        ALTER COLUMN resolution SET NOT NULL,
        ALTER COLUMN resolved_at SET NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE music.approved_artists
        ALTER COLUMN resolution SET NOT NULL,
        ALTER COLUMN resolved_at SET NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE music.approved_artists
        ALTER COLUMN resolution DROP NOT NULL,
        ALTER COLUMN resolved_at DROP NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE music.approved_albums
        ALTER COLUMN resolution DROP NOT NULL,
        ALTER COLUMN resolved_at DROP NOT NULL;
    """)

    try await sql.execute("DROP TABLE music.approved_tracks;")
  }
}
