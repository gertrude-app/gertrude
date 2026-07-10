import FluentSQL

struct AddMusicApprovedAlbumArtwork: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE music.approved_albums
      ADD COLUMN artwork jsonb;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE music.approved_albums
      DROP COLUMN artwork;
    """)
  }
}
