import FluentSQL

struct AddNativeIOSAppEventFields: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.events
      ADD COLUMN level text,
      ADD COLUMN domain text,
      ADD COLUMN app_version varchar(32);
    """)

    try await sql.execute("""
      UPDATE blocker_app.events
      SET
        level = CASE
          WHEN kind = 'error' THEN 'error'
          ELSE 'info'
        END,
        domain = CASE
          WHEN kind IN ('onboarding', 'filter', 'supervision', 'checkin') THEN kind
          ELSE NULL
        END,
        app_version = '0.0.0';
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.events
      ALTER COLUMN level SET NOT NULL,
      ALTER COLUMN app_version SET NOT NULL,
      ADD CONSTRAINT blocker_events_level_check CHECK (
        level IN ('debug', 'info', 'warning', 'error', 'critical')
      );
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.events
      DROP COLUMN kind;
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      ADD COLUMN level text,
      ADD COLUMN domain text;
    """)

    try await sql.execute("""
      UPDATE podcast_app.events
      SET
        level = CASE kind
          WHEN 'error' THEN 'error'
          WHEN 'unexpected' THEN 'warning'
          ELSE 'info'
        END,
        domain = CASE
          WHEN kind = 'subscription' THEN 'subscription'
          ELSE NULL
        END;
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      ALTER COLUMN level SET NOT NULL,
      ADD CONSTRAINT podcast_events_level_check CHECK (
        level IN ('debug', 'info', 'warning', 'error', 'critical')
      );
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      ALTER COLUMN device_id DROP NOT NULL;
    """)

    try await sql.execute("""
      INSERT INTO child.ios_devices (
        id, child_id, model_identifier, ios_version, created_at, updated_at
      )
      SELECT DISTINCT ON (device_id)
        device_id,
        NULL,
        model_identifier,
        ios_version,
        created_at,
        NOW()
      FROM podcast_app.events e
      WHERE e.device_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM child.ios_devices d WHERE d.id = e.device_id)
      ORDER BY device_id, created_at DESC;
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      ADD CONSTRAINT fk_podcast_events_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      DROP COLUMN kind,
      DROP COLUMN label;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE podcast_app.events
      DROP CONSTRAINT IF EXISTS fk_podcast_events_device_id;
    """)

    try await sql.execute("""
      DELETE FROM podcast_app.events
      WHERE device_id IS NULL;
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      ALTER COLUMN device_id SET NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      ADD COLUMN IF NOT EXISTS kind text,
      ADD COLUMN IF NOT EXISTS label text;
    """)

    try await sql.execute("""
      UPDATE podcast_app.events
      SET
        kind = CASE
          WHEN domain = 'subscription' THEN 'subscription'
          WHEN level IN ('error', 'critical') THEN 'error'
          WHEN level = 'warning' THEN 'unexpected'
          ELSE 'info'
        END,
        label = event_id;
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      DROP CONSTRAINT IF EXISTS events_kind_check,
      ALTER COLUMN kind SET NOT NULL,
      ALTER COLUMN label SET NOT NULL,
      ADD CONSTRAINT events_kind_check CHECK (
        kind IN ('error', 'unexpected', 'info', 'subscription')
      );
    """)

    try await sql.execute("""
      ALTER TABLE podcast_app.events
      DROP CONSTRAINT IF EXISTS podcast_events_level_check,
      DROP COLUMN IF EXISTS domain,
      DROP COLUMN IF EXISTS level;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.events
      ADD COLUMN IF NOT EXISTS kind text;
    """)

    try await sql.execute("""
      UPDATE blocker_app.events
      SET kind = CASE
        WHEN domain IN ('onboarding', 'filter', 'supervision', 'checkin') THEN domain
        WHEN level IN ('error', 'critical') THEN 'error'
        ELSE 'info'
      END;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.events
      DROP CONSTRAINT IF EXISTS events_kind_check,
      ALTER COLUMN kind SET NOT NULL,
      ADD CONSTRAINT events_kind_check CHECK (
        kind IN ('info', 'onboarding', 'filter', 'error', 'supervision', 'checkin')
      );
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.events
      DROP CONSTRAINT IF EXISTS blocker_events_level_check,
      DROP COLUMN IF EXISTS app_version,
      DROP COLUMN IF EXISTS domain,
      DROP COLUMN IF EXISTS level;
    """)
  }
}
