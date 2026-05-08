import FluentSQL

func installTriggers(_ sql: SQLDatabase) async throws {
  // we can't install triggers when bringing up an unmigrated database, which
  // happens during staging and other explicit database resets
  let rows = try await sql.execute("SELECT 1 FROM pg_namespace WHERE nspname = 'parent'")
  guard !rows.isEmpty else { return }

  // skip triggers during the transitional state before the iosapp -> blocker_app
  // schema rename migration runs; they'll be installed on the next boot
  let blockerAppRows = try await sql
    .execute("SELECT 1 FROM pg_namespace WHERE nspname = 'blocker_app'")
  guard !blockerAppRows.isEmpty else { return }

  try await preventSupervisedDataDeletion(sql)
}

// it's critical that deleting a supervised device is not permitted from any path
// since this would make unsupervision impossible
private func preventSupervisedDataDeletion(_ sql: SQLDatabase) async throws {
  // blocks child deletion if child has a supervised ios device
  try await sql.execute("""
    CREATE OR REPLACE FUNCTION block_supervised_child_delete()
    RETURNS TRIGGER
    LANGUAGE plpgsql AS $$
    DECLARE
      supervised_count integer;
    BEGIN
      SELECT COUNT(*) INTO supervised_count
      FROM \(table: IOSDevice.self) d
      JOIN \(table: BlockerApp.Supervision.self) s
        ON s.\(col: BlockerApp.Supervision.columnName(.deviceId)) = d.id
      WHERE d.\(col: IOSDevice.columnName(.childId)) = OLD.id
        AND s.\(col: BlockerApp.Supervision.columnName(.supervisedAt)) IS NOT NULL;

      IF supervised_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete child with supervised iOS device(s)'
          USING ERRCODE = 'P0001';
      END IF;

      RETURN OLD;
    END;
    $$;
  """)

  try await sql.execute("""
    CREATE OR REPLACE TRIGGER prevent_supervised_child_delete
    BEFORE DELETE ON \(table: Child.self)
    FOR EACH ROW
    EXECUTE FUNCTION block_supervised_child_delete();
  """)

  // blocks ios device deletion if device has active supervision
  try await sql.execute("""
    CREATE OR REPLACE FUNCTION block_supervised_device_delete()
    RETURNS TRIGGER
    LANGUAGE plpgsql AS $$
    DECLARE
      supervised_count integer;
    BEGIN
      SELECT COUNT(*) INTO supervised_count
      FROM \(table: BlockerApp.Supervision.self)
      WHERE \(col: BlockerApp.Supervision.columnName(.deviceId)) = OLD.id
        AND \(col: BlockerApp.Supervision.columnName(.supervisedAt)) IS NOT NULL;

      IF supervised_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete iOS device with active supervision'
          USING ERRCODE = 'P0001';
      END IF;

      RETURN OLD;
    END;
    $$;
  """)

  try await sql.execute("""
    CREATE OR REPLACE TRIGGER prevent_supervised_device_delete
    BEFORE DELETE ON \(table: IOSDevice.self)
    FOR EACH ROW
    EXECUTE FUNCTION block_supervised_device_delete();
  """)

  // blocks direct deletion of a supervision record for a supervised device
  try await sql.execute("""
    CREATE OR REPLACE FUNCTION block_supervised_supervision_delete()
    RETURNS TRIGGER
    LANGUAGE plpgsql AS $$
    BEGIN
      IF OLD.\(col: BlockerApp.Supervision.columnName(.supervisedAt)) IS NOT NULL THEN
        RAISE EXCEPTION 'Cannot delete supervision record for a supervised device'
          USING ERRCODE = 'P0001';
      END IF;

      RETURN OLD;
    END;
    $$;
  """)

  try await sql.execute("""
    CREATE OR REPLACE TRIGGER prevent_supervised_supervision_delete
    BEFORE DELETE ON \(table: BlockerApp.Supervision.self)
    FOR EACH ROW
    EXECUTE FUNCTION block_supervised_supervision_delete();
  """)
}
