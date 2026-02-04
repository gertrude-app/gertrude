import FluentSQL

struct SecurityEventNotificationTriggers: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.notifications
      ALTER COLUMN trigger TYPE varchar(255) USING trigger::text;
    """)

    try await sql.execute("""
      UPDATE parent.notifications
      SET trigger = 'securityEventsAll'
      WHERE trigger = 'adminChildSecurityEvent';
    """)

    try await sql.execute("""
      ALTER TABLE parent.notifications
      ADD CONSTRAINT chk_notification_trigger CHECK (
        trigger IN (
          'unlockRequestSubmitted',
          'suspendFilterRequestSubmitted',
          'securityEventsAll',
          'securityEventsMedium',
          'securityEventsRecommended'
        )
      );
    """)

    try await sql.execute("""
      DROP TYPE public.enum_parent_notification_trigger;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TYPE public.enum_parent_notification_trigger AS ENUM (
        'unlockRequestSubmitted',
        'suspendFilterRequestSubmitted',
        'adminChildSecurityEvent'
      );
    """)

    try await sql.execute("""
      UPDATE parent.notifications
      SET trigger = 'adminChildSecurityEvent'
      WHERE trigger IN ('securityEventsAll', 'securityEventsMedium', 'securityEventsRecommended');
    """)

    try await sql.execute("""
      ALTER TABLE parent.notifications
      DROP CONSTRAINT chk_notification_trigger;
    """)

    try await sql.execute("""
      ALTER TABLE parent.notifications
      ALTER COLUMN trigger TYPE public.enum_parent_notification_trigger
      USING trigger::public.enum_parent_notification_trigger;
    """)
  }
}
