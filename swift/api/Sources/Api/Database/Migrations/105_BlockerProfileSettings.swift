import FluentSQL

struct BlockerProfileSettings: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE blocker_app.profile_settings (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        is_profile_locked boolean NOT NULL DEFAULT true,
        allow_app_removal boolean NOT NULL DEFAULT false,
        allow_erase_content_and_settings boolean NOT NULL DEFAULT false,
        allow_app_installation boolean NOT NULL DEFAULT true,
        whitelisted_app_bundle_ids text[],
        web_allow_list jsonb,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY blocker_app.profile_settings
      ADD CONSTRAINT profile_settings_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY blocker_app.profile_settings
      ADD CONSTRAINT uq_profile_settings_device_id UNIQUE (device_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY blocker_app.profile_settings
      ADD CONSTRAINT fk_profile_settings_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      INSERT INTO blocker_app.profile_settings (
        id, device_id, is_profile_locked, allow_app_removal,
        allow_erase_content_and_settings, allow_app_installation,
        created_at, updated_at
      )
      SELECT
        gen_random_uuid(), device_id, is_profile_locked, allow_app_removal,
        allow_erase_content_and_settings, allow_app_installation,
        created_at, updated_at
      FROM blocker_app.installs;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.installs
      DROP COLUMN is_profile_locked,
      DROP COLUMN allow_app_removal,
      DROP COLUMN allow_erase_content_and_settings,
      DROP COLUMN allow_app_installation;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.installs
      ADD COLUMN IF NOT EXISTS is_profile_locked boolean,
      ADD COLUMN IF NOT EXISTS allow_app_removal boolean,
      ADD COLUMN IF NOT EXISTS allow_erase_content_and_settings boolean,
      ADD COLUMN IF NOT EXISTS allow_app_installation boolean;
    """)

    try await sql.execute("""
      UPDATE blocker_app.installs i
      SET is_profile_locked = s.is_profile_locked,
          allow_app_removal = s.allow_app_removal,
          allow_erase_content_and_settings = s.allow_erase_content_and_settings,
          allow_app_installation = s.allow_app_installation
      FROM blocker_app.profile_settings s
      WHERE i.device_id = s.device_id;
    """)

    try await sql.execute("""
      UPDATE blocker_app.installs
      SET is_profile_locked = COALESCE(is_profile_locked, true),
          allow_app_removal = COALESCE(allow_app_removal, false),
          allow_erase_content_and_settings = COALESCE(allow_erase_content_and_settings, false),
          allow_app_installation = COALESCE(allow_app_installation, true)
      WHERE is_profile_locked IS NULL
        OR allow_app_removal IS NULL
        OR allow_erase_content_and_settings IS NULL
        OR allow_app_installation IS NULL;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.installs
      ALTER COLUMN is_profile_locked SET NOT NULL,
      ALTER COLUMN allow_app_removal SET NOT NULL,
      ALTER COLUMN allow_erase_content_and_settings SET NOT NULL,
      ALTER COLUMN allow_app_installation SET NOT NULL,
      ALTER COLUMN allow_app_installation SET DEFAULT true;
    """)

    try await sql.execute("DROP TABLE IF EXISTS blocker_app.profile_settings;")
  }
}
