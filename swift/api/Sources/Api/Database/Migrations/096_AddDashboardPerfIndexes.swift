import FluentSQL
import Foundation

struct AddDashboardPerfIndexes: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE INDEX idx_iosapp_events_event_device
        ON blocker_app.events (event_id, device_id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_security_events_computer_user_created
        ON system.security_events (computer_user_id, created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_interesting_events_computer_user_created
        ON system.interesting_events (computer_user_id, created_at DESC);
    """)

    try await sql.execute("DROP INDEX IF EXISTS system.idx_interesting_events_computer_user_id;")

    try await sql.execute("""
      CREATE INDEX idx_podcast_events_event_device
        ON podcast_app.events (event_id, device_id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_podcast_events_device_created
        ON podcast_app.events (device_id, created_at DESC);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP INDEX IF EXISTS blocker_app.idx_iosapp_events_event_device;")
    try await sql.execute("DROP INDEX IF EXISTS system.idx_security_events_computer_user_created;")
    try await sql
      .execute("DROP INDEX IF EXISTS system.idx_interesting_events_computer_user_created;")
    try await sql.execute("DROP INDEX IF EXISTS podcast_app.idx_podcast_events_event_device;")
    try await sql.execute("DROP INDEX IF EXISTS podcast_app.idx_podcast_events_device_created;")

    try await sql.execute("""
      CREATE INDEX idx_interesting_events_computer_user_id
        ON system.interesting_events (computer_user_id);
    """)
  }
}
