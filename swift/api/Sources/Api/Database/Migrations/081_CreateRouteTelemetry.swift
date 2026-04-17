import FluentSQL
import Foundation

struct CreateRouteTelemetry: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE system.route_telemetry (
        id uuid PRIMARY KEY,
        kind text NOT NULL,
        request_id text NOT NULL,
        domain text NOT NULL,
        operation text NOT NULL,
        duration_ms integer NOT NULL,
        result text NOT NULL,
        error_id varchar(8),
        error_type text,
        error_message text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_route_telemetry_op_created
        ON system.route_telemetry (operation, created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_route_telemetry_errors
        ON system.route_telemetry (created_at DESC)
        WHERE result <> 'ok';
    """)

    try await sql.execute("""
      CREATE INDEX idx_route_telemetry_created
        ON system.route_telemetry (created_at);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE IF EXISTS system.route_telemetry;")
  }
}
