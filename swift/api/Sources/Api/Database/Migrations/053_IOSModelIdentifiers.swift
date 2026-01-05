import FluentSQL

struct IOSModelIdentifiers: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT IF EXISTS events_device_type_check;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      DROP CONSTRAINT IF EXISTS pending_supervisions_device_type_check;
    """)

    try await sql.execute("""
      UPDATE child.ios_devices
      SET device_type = CASE device_type
        WHEN 'iPhone' THEN 'iPhone,unknown'
        WHEN 'iPad' THEN 'iPad,unknown'
        ELSE device_type
      END;
    """)

    try await sql.execute("""
      UPDATE iosapp.events
      SET device_type = CASE device_type
        WHEN 'iPhone' THEN 'iPhone,unknown'
        WHEN 'iPad' THEN 'iPad,unknown'
        ELSE device_type
      END;
    """)

    try await sql.execute("""
      UPDATE iosapp.pending_supervisions
      SET device_type = CASE device_type
        WHEN 'iPhone' THEN 'iPhone,unknown'
        WHEN 'iPad' THEN 'iPad,unknown'
        ELSE device_type
      END;
    """)

    try await sql.execute("""
      UPDATE podcasts.events
      SET device_type = CASE device_type
        WHEN 'iPhone' THEN 'iPhone,unknown'
        WHEN 'iPad' THEN 'iPad,unknown'
        ELSE device_type
      END;
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices RENAME COLUMN device_type TO model_identifier;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events RENAME COLUMN device_type TO model_identifier;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions RENAME COLUMN device_type TO model_identifier;
    """)

    try await sql.execute("""
      ALTER TABLE podcasts.events RENAME COLUMN device_type TO model_identifier;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'child' AND table_name = 'ios_devices' AND column_name = 'model_identifier'
        ) THEN
          ALTER TABLE child.ios_devices RENAME COLUMN model_identifier TO device_type;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'iosapp' AND table_name = 'events' AND column_name = 'model_identifier'
        ) THEN
          ALTER TABLE iosapp.events RENAME COLUMN model_identifier TO device_type;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'iosapp' AND table_name = 'pending_supervisions' AND column_name = 'model_identifier'
        ) THEN
          ALTER TABLE iosapp.pending_supervisions RENAME COLUMN model_identifier TO device_type;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'podcasts' AND table_name = 'events' AND column_name = 'model_identifier'
        ) THEN
          ALTER TABLE podcasts.events RENAME COLUMN model_identifier TO device_type;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        UPDATE child.ios_devices
        SET device_type = CASE
          WHEN device_type LIKE 'iPhone%' THEN 'iPhone'
          WHEN device_type LIKE 'iPad%' THEN 'iPad'
          ELSE device_type
        END
        WHERE device_type NOT IN ('iPhone', 'iPad');
      EXCEPTION WHEN undefined_column THEN NULL;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        UPDATE iosapp.events
        SET device_type = CASE
          WHEN device_type LIKE 'iPhone%' THEN 'iPhone'
          WHEN device_type LIKE 'iPad%' THEN 'iPad'
          ELSE device_type
        END
        WHERE device_type NOT IN ('iPhone', 'iPad');
      EXCEPTION WHEN undefined_column THEN NULL;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        UPDATE iosapp.pending_supervisions
        SET device_type = CASE
          WHEN device_type LIKE 'iPhone%' THEN 'iPhone'
          WHEN device_type LIKE 'iPad%' THEN 'iPad'
          ELSE device_type
        END
        WHERE device_type NOT IN ('iPhone', 'iPad');
      EXCEPTION WHEN undefined_column THEN NULL;
      END $$;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        UPDATE podcasts.events
        SET device_type = CASE
          WHEN device_type LIKE 'iPhone%' THEN 'iPhone'
          WHEN device_type LIKE 'iPad%' THEN 'iPad'
          ELSE device_type
        END
        WHERE device_type NOT IN ('iPhone', 'iPad');
      EXCEPTION WHEN undefined_column THEN NULL;
      END $$;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.events
      DROP CONSTRAINT IF EXISTS events_device_type_check;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'iosapp' AND table_name = 'events' AND column_name = 'device_type'
        ) THEN
          ALTER TABLE iosapp.events
          ADD CONSTRAINT events_device_type_check
          CHECK (device_type IN ('iPhone', 'iPad'));
        END IF;
      END $$;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.pending_supervisions
      DROP CONSTRAINT IF EXISTS pending_supervisions_device_type_check;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'iosapp' AND table_name = 'pending_supervisions' AND column_name = 'device_type'
        ) THEN
          ALTER TABLE iosapp.pending_supervisions
          ADD CONSTRAINT pending_supervisions_device_type_check
          CHECK (device_type IN ('iPhone', 'iPad'));
        END IF;
      END $$;
    """)
  }
}
