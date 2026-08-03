import FluentSQL

struct AddChildRelationship: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.children
      ADD COLUMN relationship text NOT NULL DEFAULT 'child',
      ADD CONSTRAINT chk_children_relationship
        CHECK (relationship IN ('child', 'peer', 'self'));
    """)
    try await sql.execute("""
      CREATE UNIQUE INDEX uq_children_parent_self_relationship
      ON parent.children (parent_id)
      WHERE relationship = 'self';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP INDEX parent.uq_children_parent_self_relationship;
    """)
    try await sql.execute("""
      ALTER TABLE parent.children
      DROP COLUMN relationship;
    """)
  }
}
