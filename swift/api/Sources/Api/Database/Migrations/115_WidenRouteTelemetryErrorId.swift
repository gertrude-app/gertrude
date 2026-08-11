import FluentSQL

struct WidenRouteTelemetryErrorId: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.route_telemetry
        ALTER COLUMN error_id TYPE varchar(64);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      UPDATE system.route_telemetry
        SET error_id = left(error_id, 8)
        WHERE length(error_id) > 8;
    """)

    try await sql.execute("""
      ALTER TABLE system.route_telemetry
        ALTER COLUMN error_id TYPE varchar(8);
    """)
  }
}
