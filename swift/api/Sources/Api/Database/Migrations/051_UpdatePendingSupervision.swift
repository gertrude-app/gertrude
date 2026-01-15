import FluentSQL

struct UpdatePendingSupervision: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      DROP CONSTRAINT fk_pending_supervisions_claimed_by_parent_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      DROP COLUMN claimed_by_parent_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      DROP CONSTRAINT fk_pending_supervisions_child_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      RENAME COLUMN child_id TO claimed_child_id;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.pending_supervisions
      ADD CONSTRAINT fk_pending_supervisions_claimed_child_id
      FOREIGN KEY (claimed_child_id)
      REFERENCES parent.children(id) ON DELETE SET NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    let rows = try await sql.execute("""
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'iosapp'
      AND table_name = 'pending_supervisions'
      AND column_name = 'claimed_child_id'
    """)
    guard rows.first != nil else {
      return
    }

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      DROP CONSTRAINT IF EXISTS fk_pending_supervisions_claimed_child_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      RENAME COLUMN claimed_child_id TO child_id;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.pending_supervisions
      ADD CONSTRAINT fk_pending_supervisions_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      ADD COLUMN claimed_by_parent_id uuid;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.pending_supervisions
      ADD CONSTRAINT fk_pending_supervisions_claimed_by_parent_id
      FOREIGN KEY (claimed_by_parent_id)
      REFERENCES parent.parents(id) ON DELETE SET NULL;
    """)
  }
}
