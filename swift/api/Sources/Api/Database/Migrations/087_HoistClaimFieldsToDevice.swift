import FluentSQL

struct HoistClaimFieldsToDevice: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN claim_code integer,
      ADD COLUMN claim_code_expires_at timestamp with time zone,
      ADD COLUMN claimed_at timestamp with time zone;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices d
      SET claim_code = s.claim_code,
          claim_code_expires_at = s.claim_code_expires_at,
          claimed_at = s.claimed_at
      FROM blocker_app.supervisions s
      WHERE s.device_id = d.id;
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX uq_ios_devices_claim_code
      ON child.ios_devices (claim_code)
      WHERE claim_code IS NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.supervisions
      DROP CONSTRAINT IF EXISTS uq_supervisions_claim_code;
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.supervisions
      DROP COLUMN claim_code,
      DROP COLUMN claim_code_expires_at,
      DROP COLUMN claimed_at;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.supervisions
      ADD COLUMN claim_code integer,
      ADD COLUMN claim_code_expires_at timestamp with time zone,
      ADD COLUMN claimed_at timestamp with time zone;
    """)

    try await sql.execute("""
      UPDATE blocker_app.supervisions s
      SET claim_code = d.claim_code,
          claim_code_expires_at = d.claim_code_expires_at,
          claimed_at = d.claimed_at
      FROM child.ios_devices d
      WHERE d.id = s.device_id;
    """)

    // some of our tests cheat and don't set claim codes during setup
    if get(dependency: \.env.mode) != .prod {
      try await sql.execute("""
        DELETE FROM blocker_app.supervisions WHERE claim_code IS NULL;
      """)
    }

    try await sql.execute("""
      ALTER TABLE blocker_app.supervisions
      ALTER COLUMN claim_code SET NOT NULL,
      ALTER COLUMN claim_code_expires_at SET NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY blocker_app.supervisions
      ADD CONSTRAINT uq_supervisions_claim_code UNIQUE (claim_code);
    """)

    try await sql.execute("""
      DROP INDEX IF EXISTS child.uq_ios_devices_claim_code;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN claim_code,
      DROP COLUMN claim_code_expires_at,
      DROP COLUMN claimed_at;
    """)
  }
}
