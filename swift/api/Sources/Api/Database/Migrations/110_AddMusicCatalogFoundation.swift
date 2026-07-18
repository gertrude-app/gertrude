import FluentSQL

struct AddMusicCatalogFoundation: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE music.approved_albums
      ADD COLUMN resolution jsonb,
      ADD COLUMN resolved_at timestamp with time zone;
    """)

    try await sql.execute("""
      ALTER TABLE music.approved_artists
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
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE music.library_snapshots;")
    try await sql.execute("""
      ALTER TABLE music.approved_artists
      DROP COLUMN resolved_at,
      DROP COLUMN resolution;
    """)
    try await sql.execute("""
      ALTER TABLE music.approved_albums
      DROP COLUMN resolved_at,
      DROP COLUMN resolution;
    """)
  }
}
