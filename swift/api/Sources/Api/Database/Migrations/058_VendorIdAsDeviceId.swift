import FluentSQL

struct VendorIdAsDeviceId: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    // 1. drop all fk constraints that reference ios_devices.id
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      DROP CONSTRAINT fk_block_rules_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.device_block_groups
      DROP CONSTRAINT fk_device_block_groups_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE child.iosapp_tokens
      DROP CONSTRAINT fk_iosapp_tokens_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      DROP CONSTRAINT fk_screenshots_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.suspend_filter_requests
      DROP CONSTRAINT fk_suspend_filter_requests_iosapp_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.web_policy_domains
      DROP CONSTRAINT fk_web_policy_domains_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT fk_events_ios_device_id;
    """)

    try await sql.execute("""
      DROP INDEX IF EXISTS iosapp.idx_events_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP COLUMN ios_device_id;
    """)

    // 2. update fk columns in referencing tables to use vendor_id
    try await sql.execute("""
      UPDATE iosapp.block_rules br
      SET device_id = d.vendor_id
      FROM child.ios_devices d
      WHERE br.device_id = d.id;
    """)

    try await sql.execute("""
      UPDATE iosapp.device_block_groups dbg
      SET device_id = d.vendor_id
      FROM child.ios_devices d
      WHERE dbg.device_id = d.id;
    """)

    try await sql.execute("""
      UPDATE child.iosapp_tokens t
      SET device_id = d.vendor_id
      FROM child.ios_devices d
      WHERE t.device_id = d.id;
    """)

    try await sql.execute("""
      UPDATE child.screenshots s
      SET ios_device_id = d.vendor_id
      FROM child.ios_devices d
      WHERE s.ios_device_id = d.id;
    """)

    try await sql.execute("""
      UPDATE iosapp.suspend_filter_requests sfr
      SET device_id = d.vendor_id
      FROM child.ios_devices d
      WHERE sfr.device_id = d.id;
    """)

    try await sql.execute("""
      UPDATE iosapp.web_policy_domains wpd
      SET device_id = d.vendor_id
      FROM child.ios_devices d
      WHERE wpd.device_id = d.id;
    """)

    // 3. update ios_devices.id to be the vendor_id
    try await sql.execute("""
      UPDATE child.ios_devices
      SET id = vendor_id;
    """)

    // 4. drop the now-redundant vendor_id column from ios_devices
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN vendor_id;
    """)

    // 5. make child_id nullable (device can exist before being claimed)
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ALTER COLUMN child_id DROP NOT NULL;
    """)

    // 6. add supervision claim fields to ios_devices
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN supervision_claim_code integer,
      ADD COLUMN claim_code_expires_at timestamp with time zone;
    """)

    // 7. create unique index on claim code (only for non-null codes)
    try await sql.execute("""
      CREATE UNIQUE INDEX idx_ios_devices_supervision_claim_code
      ON child.ios_devices (supervision_claim_code)
      WHERE supervision_claim_code IS NOT NULL;
    """)

    // 8. backfill ios_devices from events table
    try await sql.execute("""
      INSERT INTO child.ios_devices (
        id, child_id, model_identifier, app_version, ios_version,
        web_policy, is_supervised, is_profile_installed, created_at, updated_at
      )
      SELECT DISTINCT ON (vendor_id)
        vendor_id,
        NULL,
        model_identifier,
        '0.0.0',
        ios_version,
        'blockAll',
        false,
        false,
        created_at,
        NOW()
      FROM iosapp.events
      WHERE vendor_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM child.ios_devices WHERE id = vendor_id)
      ORDER BY vendor_id, created_at DESC;
    """)

    // 9. for block_rules with vendor_id only, set device_id = vendor_id
    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET device_id = vendor_id
      WHERE device_id IS NULL AND vendor_id IS NOT NULL;
    """)

    // 10. drop the now-redundant vendor_id column from block_rules
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      DROP COLUMN vendor_id;
    """)

    // 11. re-add fk constraints
    try await sql.execute("""
      DELETE FROM iosapp.block_rules
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      ADD CONSTRAINT fk_block_rules_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM iosapp.device_block_groups
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.device_block_groups
      ADD CONSTRAINT fk_device_block_groups_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM child.iosapp_tokens
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE child.iosapp_tokens
      ADD CONSTRAINT fk_iosapp_tokens_ios_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM child.screenshots
      WHERE ios_device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE child.screenshots
      ADD CONSTRAINT fk_screenshots_ios_device_id
      FOREIGN KEY (ios_device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM iosapp.suspend_filter_requests
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.suspend_filter_requests
      ADD CONSTRAINT fk_suspend_filter_requests_iosapp_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM iosapp.web_policy_domains
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.web_policy_domains
      ADD CONSTRAINT fk_web_policy_domains_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    // 12. rename events.vendor_id -> device_id for consistency
    try await sql.execute("""
      ALTER TABLE iosapp.events
      RENAME COLUMN vendor_id TO device_id;
    """)

    // 13. add fk on events.device_id -> ios_devices.id
    try await sql.execute("""
      DELETE FROM iosapp.events
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.events
      ADD CONSTRAINT fk_events_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE SET NULL;
    """)

    // 14. drop pending_supervisions table (no longer needed)
    try await sql.execute("""
      DROP TABLE IF EXISTS iosapp.pending_supervisions;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    // recreate pending_supervisions table
    try await sql.execute("""
      CREATE TABLE IF NOT EXISTS iosapp.pending_supervisions (
        id uuid NOT NULL PRIMARY KEY,
        code integer NOT NULL,
        vendor_id uuid NOT NULL,
        model_identifier varchar(64) NOT NULL,
        ios_version varchar(32) NOT NULL,
        app_version varchar(32) NOT NULL,
        claimed_child_id uuid REFERENCES parent.children(id) ON DELETE SET NULL,
        expires_at timestamp with time zone NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_supervisions_code
      ON iosapp.pending_supervisions (code);
    """)

    try await sql.execute("""
      CREATE INDEX IF NOT EXISTS idx_pending_supervisions_vendor_id
      ON iosapp.pending_supervisions (vendor_id);
    """)

    // check if migration was applied by looking for vendor_id column in ios_devices
    // if vendor_id exists, the migration wasn't applied (or was already rolled back)
    let rows = try await sql.execute("""
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'child'
      AND table_name = 'ios_devices'
      AND column_name = 'vendor_id'
    """)

    if rows.first != nil {
      return
    }

    // remove the new fk on events.device_id
    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT IF EXISTS fk_events_device_id;
    """)

    // rename events.device_id back to vendor_id (if column exists)
    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'iosapp'
                   AND table_name = 'events'
                   AND column_name = 'device_id') THEN
          ALTER TABLE iosapp.events RENAME COLUMN device_id TO vendor_id;
        END IF;
      END $$;
    """)

    // drop all fk constraints
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      DROP CONSTRAINT IF EXISTS fk_block_rules_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.device_block_groups
      DROP CONSTRAINT IF EXISTS fk_device_block_groups_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE child.iosapp_tokens
      DROP CONSTRAINT IF EXISTS fk_iosapp_tokens_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      DROP CONSTRAINT IF EXISTS fk_screenshots_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.suspend_filter_requests
      DROP CONSTRAINT IF EXISTS fk_suspend_filter_requests_iosapp_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.web_policy_domains
      DROP CONSTRAINT IF EXISTS fk_web_policy_domains_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT IF EXISTS fk_events_ios_device_id;
    """)

    // add vendor_id column back to block_rules BEFORE deleting backfilled devices
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      ADD COLUMN vendor_id uuid;
    """)

    // for block_rules pointing to backfilled devices, move device_id to vendor_id
    try await sql.execute("""
      UPDATE iosapp.block_rules br
      SET vendor_id = device_id, device_id = NULL
      FROM child.ios_devices d
      WHERE br.device_id = d.id AND d.child_id IS NULL;
    """)

    // delete backfilled devices (those with null child_id)
    try await sql.execute("""
      DELETE FROM child.ios_devices
      WHERE child_id IS NULL;
    """)

    // drop supervision claim columns and index
    try await sql.execute("""
      DROP INDEX IF EXISTS child.idx_ios_devices_supervision_claim_code;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN IF EXISTS supervision_claim_code,
      DROP COLUMN IF EXISTS claim_code_expires_at;
    """)

    // make child_id not null again (only if there are no NULLs)
    try await sql.execute("""
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM child.ios_devices WHERE child_id IS NULL) THEN
          ALTER TABLE child.ios_devices ALTER COLUMN child_id SET NOT NULL;
        END IF;
      END $$;
    """)

    // add vendor_id column back to ios_devices and set it equal to id
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN vendor_id uuid;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices
      SET vendor_id = id;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ALTER COLUMN vendor_id SET NOT NULL;
    """)

    // re-add fk constraints
    try await sql.execute("""
      DELETE FROM iosapp.block_rules
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      ADD CONSTRAINT fk_block_rules_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM iosapp.device_block_groups
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.device_block_groups
      ADD CONSTRAINT fk_device_block_groups_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM child.iosapp_tokens
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE child.iosapp_tokens
      ADD CONSTRAINT fk_iosapp_tokens_ios_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM child.screenshots
      WHERE ios_device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE child.screenshots
      ADD CONSTRAINT fk_screenshots_ios_device_id
      FOREIGN KEY (ios_device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM iosapp.suspend_filter_requests
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.suspend_filter_requests
      ADD CONSTRAINT fk_suspend_filter_requests_iosapp_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DELETE FROM iosapp.web_policy_domains
      WHERE device_id NOT IN (SELECT id FROM child.ios_devices);
    """)
    try await sql.execute("""
      ALTER TABLE iosapp.web_policy_domains
      ADD CONSTRAINT fk_web_policy_domains_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_schema = 'iosapp'
                       AND table_name = 'events'
                       AND column_name = 'ios_device_id') THEN
          ALTER TABLE iosapp.events ADD COLUMN ios_device_id uuid;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_events_ios_device_id') THEN
          ALTER TABLE iosapp.events
          ADD CONSTRAINT fk_events_ios_device_id
          FOREIGN KEY (ios_device_id)
          REFERENCES child.ios_devices(id) ON DELETE SET NULL;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      CREATE INDEX IF NOT EXISTS idx_events_ios_device_id
      ON iosapp.events (ios_device_id);
    """)
  }
}
