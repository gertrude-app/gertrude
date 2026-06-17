import FluentSQL

struct PodcastAppTokenInstallUnique: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE podcast_app.tokens
      ADD CONSTRAINT uq_tokens_install_id UNIQUE (install_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE podcast_app.tokens
      DROP CONSTRAINT IF EXISTS uq_tokens_install_id;
    """)
  }
}
