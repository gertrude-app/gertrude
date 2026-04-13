import FluentSQL

struct AddSmsSendTwilioFields: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.sms_sends
      ADD COLUMN twilio_message_sid varchar(48),
      ADD COLUMN num_segments smallint;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.sms_sends
      DROP COLUMN IF EXISTS twilio_message_sid,
      DROP COLUMN IF EXISTS num_segments;
    """)
  }
}
