import FluentSQL
import Foundation

struct StripeSubsCleanup: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DELETE FROM parent.subscriptions
       WHERE billing_status IS NULL
          OR billing_status::TEXT IN ('cancelled', 'unpaid')
          OR (stripe_id IS NULL
              AND billing_status::TEXT IN
                ('trialing', 'trialExpiringSoon', 'trialExpired'));
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
        DROP COLUMN billing_status,
        DROP COLUMN trial_started_at,
        DROP COLUMN status_expires_at,
        ALTER COLUMN current_period_end SET NOT NULL,
        ALTER COLUMN stripe_status      SET NOT NULL,
        ALTER COLUMN stripe_id          SET NOT NULL;
    """)

    try await sql.execute("""
      DROP TYPE parent.billing_status;
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions RENAME TO stripe_subscriptions;
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
        ADD CONSTRAINT stripe_subscriptions_parent_in_billing_identities
          FOREIGN KEY (parent_id) REFERENCES parent.billing_identities (parent_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
        DROP CONSTRAINT IF EXISTS
          stripe_subscriptions_parent_in_billing_identities;
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions RENAME TO subscriptions;
    """)

    try await sql.execute("""
      CREATE TYPE parent.billing_status AS ENUM (
        'trialing',
        'trialExpiringSoon',
        'trialExpired',
        'paid',
        'overdue',
        'unpaid',
        'cancelled'
      );
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
        ADD COLUMN billing_status parent.billing_status,
        ADD COLUMN trial_started_at TIMESTAMP WITH TIME ZONE,
        ADD COLUMN status_expires_at TIMESTAMP WITH TIME ZONE,
        ALTER COLUMN current_period_end DROP NOT NULL,
        ALTER COLUMN stripe_status      DROP NOT NULL,
        ALTER COLUMN stripe_id          DROP NOT NULL;
    """)
  }
}
