import FluentSQL

struct CreateIOSDeviceTransitions: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE child.ios_device_transitions (
        id uuid PRIMARY KEY,
        old_device_id uuid NOT NULL REFERENCES child.ios_devices(id) ON DELETE CASCADE,
        new_device_id uuid NOT NULL REFERENCES child.ios_devices(id) ON DELETE CASCADE,
        kind text NOT NULL CHECK (kind IN ('migrated', 'same_device')),
        app text NOT NULL CHECK (app IN ('blocker', 'music', 'podcasts')),
        verified boolean NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (old_device_id, new_device_id, app)
      );
    """)
    try await sql.execute("""
      CREATE INDEX ON child.ios_device_transitions (new_device_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE child.ios_device_transitions;")
  }
}
