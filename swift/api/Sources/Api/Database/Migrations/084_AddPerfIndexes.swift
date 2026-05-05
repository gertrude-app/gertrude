import FluentSQL
import Foundation

struct AddPerfIndexes: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE INDEX idx_screenshots_computer_user_created
        ON child.screenshots (computer_user_id, created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_keystroke_lines_computer_user_created
        ON macapp.keystroke_lines (computer_user_id, created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_interesting_events_computer_user_id
        ON system.interesting_events (computer_user_id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_security_events_parent_created
        ON system.security_events (parent_id, created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_iosapp_events_device_created
        ON iosapp.events (device_id, created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_ios_devices_child_id
        ON child.ios_devices (child_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP INDEX IF EXISTS child.idx_screenshots_computer_user_created;")
    try await sql.execute("DROP INDEX IF EXISTS macapp.idx_keystroke_lines_computer_user_created;")
    try await sql.execute("DROP INDEX IF EXISTS system.idx_interesting_events_computer_user_id;")
    try await sql.execute("DROP INDEX IF EXISTS system.idx_security_events_parent_created;")
    try await sql.execute("DROP INDEX IF EXISTS iosapp.idx_iosapp_events_device_created;")
    try await sql.execute("DROP INDEX IF EXISTS child.idx_ios_devices_child_id;")
  }
}
