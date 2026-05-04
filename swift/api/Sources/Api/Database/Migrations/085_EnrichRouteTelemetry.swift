import FluentSQL
import Foundation

struct EnrichRouteTelemetry: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.route_telemetry
        ADD COLUMN parent_id uuid,
        ADD COLUMN ip_address text,
        ADD COLUMN user_agent text,
        ADD COLUMN request_bytes integer,
        ADD COLUMN response_bytes integer;
    """)

    try await sql.execute("""
      CREATE INDEX idx_route_telemetry_parent_created
        ON system.route_telemetry (parent_id, created_at DESC)
        WHERE parent_id IS NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP INDEX IF EXISTS system.idx_route_telemetry_parent_created;
    """)
    try await sql.execute("""
      ALTER TABLE system.route_telemetry
        DROP COLUMN IF EXISTS parent_id,
        DROP COLUMN IF EXISTS ip_address,
        DROP COLUMN IF EXISTS user_agent,
        DROP COLUMN IF EXISTS request_bytes,
        DROP COLUMN IF EXISTS response_bytes;
    """)
  }
}
