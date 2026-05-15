import FluentSQL

struct BlockerAppTokenInstallFk: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      ADD COLUMN install_id uuid;
    """)

    try await sql.execute("""
      UPDATE blocker_app.tokens t
      SET install_id = i.id
      FROM blocker_app.installs i
      WHERE i.device_id = t.device_id;
    """)

    try await sql.execute("""
      DO $$
      DECLARE
        orphan_count integer;
      BEGIN
        SELECT count(*) INTO orphan_count
        FROM blocker_app.tokens
        WHERE install_id IS NULL;
        IF orphan_count > 0 THEN
          RAISE EXCEPTION
            'blocker_app.tokens has % rows with no matching blocker_app.installs row (matched on device_id) — refusing to migrate. fix data upstream.',
            orphan_count;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      ALTER COLUMN install_id SET NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      DROP CONSTRAINT fk_iosapp_tokens_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      ADD CONSTRAINT fk_tokens_install_id
      FOREIGN KEY (install_id)
      REFERENCES blocker_app.installs(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      DROP COLUMN device_id;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      ADD COLUMN device_id uuid;
    """)

    try await sql.execute("""
      UPDATE blocker_app.tokens t
      SET device_id = i.device_id
      FROM blocker_app.installs i
      WHERE i.id = t.install_id;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      ALTER COLUMN device_id SET NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      DROP CONSTRAINT fk_tokens_install_id;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      ADD CONSTRAINT fk_iosapp_tokens_ios_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      DROP COLUMN install_id;
    """)
  }
}
