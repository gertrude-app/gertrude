import FluentSQL

struct CreateSupervisionTable: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.supervisions (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        claim_code integer NOT NULL,
        claim_code_expires_at timestamp with time zone NOT NULL,
        udid varchar(64),
        claimed_at timestamp with time zone,
        supervised_at timestamp with time zone,
        profile_installed_at timestamp with time zone,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.supervisions
      ADD CONSTRAINT supervisions_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.supervisions
      ADD CONSTRAINT uq_supervisions_device_id UNIQUE (device_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.supervisions
      ADD CONSTRAINT uq_supervisions_claim_code UNIQUE (claim_code);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.supervisions
      ADD CONSTRAINT fk_supervisions_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS is_supervised;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS is_profile_installed;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS supervision_claim_code;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS claim_code_expires_at;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS udid;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN is_supervised boolean NOT NULL DEFAULT false;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN is_profile_installed boolean NOT NULL DEFAULT false;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN supervision_claim_code integer;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN claim_code_expires_at timestamp with time zone;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN udid varchar(64);
    """)

    try await sql.execute("""
      DROP TABLE IF EXISTS iosapp.supervisions;
    """)
  }
}
