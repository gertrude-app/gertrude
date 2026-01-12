import FluentSQL

struct SupervisionStateBooleans: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN is_supervised boolean NOT NULL DEFAULT false;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN is_profile_installed boolean NOT NULL DEFAULT false;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices
      SET is_supervised = (supervised_at IS NOT NULL),
          is_profile_installed = (profile_first_installed_at IS NOT NULL);
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN supervised_at;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN profile_first_installed_at;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      ADD COLUMN ios_device_id uuid;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      ADD CONSTRAINT fk_events_ios_device_id
      FOREIGN KEY (ios_device_id)
      REFERENCES child.ios_devices(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      CREATE INDEX idx_events_ios_device_id
      ON iosapp.events (ios_device_id);
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT events_kind_check;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      ADD CONSTRAINT events_kind_check
      CHECK (kind IN ('info', 'onboarding', 'filter', 'error', 'supervision'));
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT events_kind_check;
    """)

    try await sql.execute("""
      UPDATE iosapp.events
      SET kind = 'onboarding'
      WHERE kind = 'supervision';
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      ADD CONSTRAINT events_kind_check
      CHECK (kind IN ('info', 'onboarding', 'filter', 'error'));
    """)
    try await sql.execute("""
      DROP INDEX IF EXISTS iosapp.idx_events_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT IF EXISTS fk_events_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP COLUMN IF EXISTS ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN supervised_at TIMESTAMPTZ;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN profile_first_installed_at TIMESTAMPTZ;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices
      SET supervised_at = CASE WHEN is_supervised THEN created_at ELSE NULL END,
          profile_first_installed_at = CASE WHEN is_profile_installed THEN created_at ELSE NULL END;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS is_supervised;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS is_profile_installed;
    """)
  }
}
