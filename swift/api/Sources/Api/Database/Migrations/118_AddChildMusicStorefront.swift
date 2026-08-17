import FluentSQL

struct AddChildMusicStorefront: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.children
      ADD COLUMN apple_music_storefront text NOT NULL DEFAULT 'us';
    """)

    try await sql.execute("""
      ALTER TABLE parent.children
      ADD CONSTRAINT ck_children_apple_music_storefront
      CHECK (apple_music_storefront ~ '^[a-z]{2}$');
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.children
      DROP COLUMN IF EXISTS apple_music_storefront;
    """)
  }
}
