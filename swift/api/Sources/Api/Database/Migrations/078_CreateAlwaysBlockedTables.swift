import FluentSQL
import Foundation

struct CreateAlwaysBlockedTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE macapp.always_blocked_groups (
        id uuid PRIMARY KEY,
        name text NOT NULL,
        description text NOT NULL,
        long_description text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE TABLE macapp.always_blocked_rules (
        id uuid PRIMARY KEY,
        group_id uuid NOT NULL REFERENCES macapp.always_blocked_groups(id) ON DELETE CASCADE,
        rule jsonb NOT NULL,
        comment text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_always_blocked_rules_group_id
        ON macapp.always_blocked_rules (group_id);
    """)

    try await sql.execute("""
      CREATE TABLE child.always_blocked_groups (
        id uuid PRIMARY KEY,
        child_id uuid NOT NULL REFERENCES parent.children(id) ON DELETE CASCADE,
        group_id uuid NOT NULL REFERENCES macapp.always_blocked_groups(id) ON DELETE CASCADE,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_child_always_blocked_group UNIQUE (child_id, group_id)
      );
    """)

    try await sql.execute("""
      CREATE TABLE child.always_blocked_rules (
        id uuid PRIMARY KEY,
        child_id uuid NOT NULL REFERENCES parent.children(id) ON DELETE CASCADE,
        rule jsonb NOT NULL,
        comment text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_child_always_blocked_rules_child_id
        ON child.always_blocked_rules (child_id);
    """)

    try await sql.execute("""
      ALTER TABLE child.keychains
        ADD CONSTRAINT uq_child_keychain UNIQUE (child_id, keychain_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.keychains DROP CONSTRAINT IF EXISTS uq_child_keychain;
    """)
    try await sql.execute("DROP TABLE IF EXISTS child.always_blocked_rules;")
    try await sql.execute("DROP TABLE IF EXISTS child.always_blocked_groups;")
    try await sql.execute("DROP TABLE IF EXISTS macapp.always_blocked_rules;")
    try await sql.execute("DROP TABLE IF EXISTS macapp.always_blocked_groups;")
  }
}
