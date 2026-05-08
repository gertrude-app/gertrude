import FluentSQL

struct AppInstallTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("ALTER SCHEMA iosapp RENAME TO blocker_app;")
    try await sql.execute("ALTER SCHEMA podcasts RENAME TO podcast_app;")

    try await sql.execute("""
      CREATE TABLE blocker_app.installs (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        app_version varchar NOT NULL,
        web_policy varchar NOT NULL,
        is_profile_locked boolean NOT NULL,
        allow_app_removal boolean NOT NULL,
        allow_erase_content_and_settings boolean NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY blocker_app.installs
      ADD CONSTRAINT installs_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY blocker_app.installs
      ADD CONSTRAINT uq_installs_device_id UNIQUE (device_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY blocker_app.installs
      ADD CONSTRAINT fk_installs_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      INSERT INTO blocker_app.installs (
        id, device_id, app_version, web_policy, is_profile_locked,
        allow_app_removal, allow_erase_content_and_settings,
        created_at, updated_at
      )
      SELECT
        gen_random_uuid(), id, app_version, web_policy, is_profile_locked,
        allow_app_removal, allow_erase_content_and_settings,
        created_at, updated_at
      FROM child.ios_devices;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN app_version,
      DROP COLUMN web_policy,
      DROP COLUMN is_profile_locked,
      DROP COLUMN allow_app_removal,
      DROP COLUMN allow_erase_content_and_settings;
    """)

    try await sql.execute("ALTER TABLE child.iosapp_tokens SET SCHEMA blocker_app;")
    try await sql.execute("ALTER TABLE blocker_app.iosapp_tokens RENAME TO tokens;")
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.tables
          WHERE table_schema = 'blocker_app' AND table_name = 'tokens'
        ) THEN
          ALTER TABLE blocker_app.tokens RENAME TO iosapp_tokens;
          ALTER TABLE blocker_app.iosapp_tokens SET SCHEMA child;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN IF NOT EXISTS app_version varchar,
      ADD COLUMN IF NOT EXISTS web_policy varchar,
      ADD COLUMN IF NOT EXISTS is_profile_locked boolean,
      ADD COLUMN IF NOT EXISTS allow_app_removal boolean,
      ADD COLUMN IF NOT EXISTS allow_erase_content_and_settings boolean;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices d
      SET app_version = i.app_version,
          web_policy = i.web_policy,
          is_profile_locked = i.is_profile_locked,
          allow_app_removal = i.allow_app_removal,
          allow_erase_content_and_settings = i.allow_erase_content_and_settings
      FROM blocker_app.installs i
      WHERE d.id = i.device_id AND d.app_version IS NULL;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices
      SET app_version = COALESCE(app_version, '0.0.0'),
          web_policy = COALESCE(web_policy, 'blockAll'),
          is_profile_locked = COALESCE(is_profile_locked, true),
          allow_app_removal = COALESCE(allow_app_removal, false),
          allow_erase_content_and_settings = COALESCE(allow_erase_content_and_settings, false)
      WHERE app_version IS NULL;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ALTER COLUMN app_version SET NOT NULL,
      ALTER COLUMN web_policy SET NOT NULL,
      ALTER COLUMN is_profile_locked SET NOT NULL,
      ALTER COLUMN allow_app_removal SET NOT NULL,
      ALTER COLUMN allow_erase_content_and_settings SET NOT NULL;
    """)

    try await sql.execute("DROP TABLE IF EXISTS blocker_app.installs;")

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'podcast_app') THEN
          ALTER SCHEMA podcast_app RENAME TO podcasts;
        END IF;
        IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'blocker_app') THEN
          ALTER SCHEMA blocker_app RENAME TO iosapp;
        END IF;
      END $$;
    """)
  }
}
