import FluentSQL
import Foundation

struct PendingSupervisions: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.pending_supervisions (
        id uuid NOT NULL,
        code integer NOT NULL,
        vendor_id uuid NOT NULL,
        device_type varchar(32) NOT NULL CHECK (device_type IN ('iPhone', 'iPad')),
        ios_version varchar(32) NOT NULL,
        app_version varchar(32) NOT NULL,
        claimed_by_parent_id uuid,
        child_id uuid,
        expires_at timestamp with time zone NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.pending_supervisions
      ADD CONSTRAINT iosapp_pending_supervisions_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX idx_pending_supervisions_code
      ON iosapp.pending_supervisions (code);
    """)

    try await sql.execute("""
      CREATE INDEX idx_pending_supervisions_vendor_id
      ON iosapp.pending_supervisions (vendor_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.pending_supervisions
      ADD CONSTRAINT fk_pending_supervisions_claimed_by_parent_id
      FOREIGN KEY (claimed_by_parent_id)
      REFERENCES parent.parents(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.pending_supervisions
      ADD CONSTRAINT fk_pending_supervisions_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN supervised_at TIMESTAMPTZ;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN udid TEXT;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN profile_first_installed_at TIMESTAMPTZ;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN profile_first_installed_at;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN udid;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN supervised_at;
    """)

    try await sql.execute("""
      DROP TABLE iosapp.pending_supervisions;
    """)
  }
}
