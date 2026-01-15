import FluentSQL

struct FixSearchPathTrigger: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE OR REPLACE FUNCTION set_search_path_on_login()
      RETURNS event_trigger
      SECURITY DEFINER
      LANGUAGE plpgsql AS $$
      DECLARE
        schema_list text;
      BEGIN
        SELECT 'public, ' || string_agg(schema_name, ', ' ORDER BY schema_name)
        INTO schema_list
        FROM information_schema.schemata
        WHERE schema_name NOT LIKE 'pg_%'
          AND schema_name NOT IN ('information_schema', 'public');
        EXECUTE 'SET search_path TO ' || schema_list;
      END;
      $$;
    """)

    try await sql.execute("""
      DROP TABLE IF EXISTS appstore._fluent_migrations;
    """)

    try await sql.execute("""
      DROP TABLE IF EXISTS appstore._jobs_meta;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE OR REPLACE FUNCTION set_search_path_on_login()
      RETURNS event_trigger
      SECURITY DEFINER
      LANGUAGE plpgsql AS $$
      DECLARE
        schema_list text;
      BEGIN
        SELECT string_agg(schema_name, ', ' ORDER BY schema_name) INTO schema_list
        FROM information_schema.schemata
        WHERE schema_name NOT LIKE 'pg_%'
          AND schema_name != 'information_schema';
        EXECUTE 'SET search_path TO ' || schema_list;
      END;
      $$;
    """)
  }
}
