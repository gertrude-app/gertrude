import FluentSQL

struct ClaimsCutover: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await self.createClaimsTableUp(sql: sql)
    try await self.dropDeviceClaimMirrorUp(sql: sql)
    try await self.blockerAppTokenInstallUniqueUp(sql: sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await self.blockerAppTokenInstallUniqueDown(sql: sql)
    try await self.dropDeviceClaimMirrorDown(sql: sql)
    try await self.createClaimsTableDown(sql: sql)
  }

  private func createClaimsTableUp(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE child.claims (
        id uuid NOT NULL,
        code integer NOT NULL,
        intent text NOT NULL,
        device_id uuid NOT NULL,
        child_id uuid,
        expires_at timestamp with time zone NOT NULL,
        claimed_at timestamp with time zone,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        CONSTRAINT chk_claimed_has_child CHECK (claimed_at IS NULL OR child_id IS NOT NULL)
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.claims
      ADD CONSTRAINT claims_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.claims
      ADD CONSTRAINT uq_claims_code UNIQUE (code);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.claims
      ADD CONSTRAINT fk_claims_device_id
      FOREIGN KEY (device_id) REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.claims
      ADD CONSTRAINT fk_claims_child_id
      FOREIGN KEY (child_id) REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("CREATE INDEX idx_claims_device_id ON child.claims (device_id);")
  }

  private func createClaimsTableDown(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE child.claims;")
  }

  private func dropDeviceClaimMirrorUp(sql: SQLDatabase) async throws {
    try await sql.execute("""
      INSERT INTO child.claims (
        id, code, intent, device_id, child_id, expires_at, claimed_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        d.claim_code,
        CASE
          WHEN EXISTS (
            SELECT 1 FROM blocker_app.supervisions s WHERE s.device_id = d.id
          ) THEN 'blockerSupervise'
          WHEN EXISTS (SELECT 1 FROM music_app.installs mi WHERE mi.device_id = d.id)
            AND NOT EXISTS (SELECT 1 FROM podcast_app.installs pi WHERE pi.device_id = d.id)
            THEN 'music'
          WHEN EXISTS (SELECT 1 FROM podcast_app.installs pi WHERE pi.device_id = d.id)
            AND NOT EXISTS (SELECT 1 FROM music_app.installs mi WHERE mi.device_id = d.id)
            THEN 'podcasts'
          WHEN EXISTS (SELECT 1 FROM music_app.installs mi WHERE mi.device_id = d.id)
            THEN 'music'
          WHEN EXISTS (SELECT 1 FROM podcast_app.installs pi WHERE pi.device_id = d.id)
            THEN 'podcasts'
          ELSE 'blockerSupervise'
        END,
        d.id,
        d.child_id,
        COALESCE(d.claim_code_expires_at, now() + interval '7 days'),
        d.claimed_at,
        now(),
        now()
      FROM child.ios_devices d
      WHERE d.claim_code IS NOT NULL;
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX uq_claims_device_intent_unclaimed
      ON child.claims (device_id, intent)
      WHERE claimed_at IS NULL;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN claim_code,
      DROP COLUMN claim_code_expires_at,
      DROP COLUMN claimed_at;
    """)
  }

  private func dropDeviceClaimMirrorDown(sql: SQLDatabase) async throws {
    try await sql.execute("DROP INDEX child.uq_claims_device_intent_unclaimed;")

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN claim_code integer,
      ADD COLUMN claim_code_expires_at timestamp with time zone,
      ADD COLUMN claimed_at timestamp with time zone;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices d SET
        claim_code = cl.code,
        claim_code_expires_at = cl.expires_at,
        claimed_at = cl.claimed_at
      FROM (
        SELECT DISTINCT ON (device_id) device_id, code, expires_at, claimed_at
        FROM child.claims
        ORDER BY device_id, created_at DESC
      ) cl
      WHERE cl.device_id = d.id;
    """)
  }

  private func blockerAppTokenInstallUniqueUp(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DELETE FROM blocker_app.tokens t
      WHERE EXISTS (
        SELECT 1 FROM blocker_app.tokens o
        WHERE o.install_id = t.install_id
          AND (o.created_at > t.created_at
            OR (o.created_at = t.created_at AND o.id > t.id))
      );
    """)

    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      ADD CONSTRAINT uq_tokens_install_id UNIQUE (install_id);
    """)
  }

  private func blockerAppTokenInstallUniqueDown(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE blocker_app.tokens
      DROP CONSTRAINT IF EXISTS uq_tokens_install_id;
    """)
  }
}
