import FluentSQL

struct PodcastDeviceId: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE podcasts.events
      RENAME COLUMN install_id TO device_id;
    """)
    try await sql.execute("""
      ALTER TABLE podcasts.events
      ALTER COLUMN device_id SET NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE podcasts.events
      ALTER COLUMN device_id DROP NOT NULL;
    """)
    try await sql.execute("""
      ALTER TABLE podcasts.events
      RENAME COLUMN device_id TO install_id;
    """)
  }
}
