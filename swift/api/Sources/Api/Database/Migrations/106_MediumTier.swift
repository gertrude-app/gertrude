import FluentSQL

struct MediumTier: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP CONSTRAINT IF EXISTS chk_stripe_subscription_tier;
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD CONSTRAINT chk_stripe_subscription_tier
      CHECK (tier IN ('light', 'medium', 'full'));
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conrelid = 'parent.stripe_subscriptions'::regclass
            AND conname = 'light_tier_requires_stripe_id'
        ) THEN
          ALTER TABLE parent.stripe_subscriptions
          RENAME CONSTRAINT light_tier_requires_stripe_id TO non_full_tier_requires_stripe_id;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      DROP CONSTRAINT IF EXISTS billing_identities_last_paid_tier_check;
    """)

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      ADD CONSTRAINT billing_identities_last_paid_tier_check
      CHECK (last_paid_tier IS NULL OR last_paid_tier IN ('light', 'medium', 'full'));
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      DROP CONSTRAINT IF EXISTS billing_identities_last_paid_tier_check;
    """)

    try await sql.execute("""
      UPDATE parent.billing_identities
      SET last_paid_tier = 'light'
      WHERE last_paid_tier = 'medium';
    """)

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      ADD CONSTRAINT billing_identities_last_paid_tier_check
      CHECK (last_paid_tier IS NULL OR last_paid_tier IN ('light', 'full'));
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conrelid = 'parent.stripe_subscriptions'::regclass
            AND conname = 'non_full_tier_requires_stripe_id'
        ) THEN
          ALTER TABLE parent.stripe_subscriptions
          RENAME CONSTRAINT non_full_tier_requires_stripe_id TO light_tier_requires_stripe_id;
        END IF;
      END $$;
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP CONSTRAINT IF EXISTS chk_stripe_subscription_tier;
    """)

    try await sql.execute("""
      UPDATE parent.stripe_subscriptions
      SET tier = 'light'
      WHERE tier = 'medium';
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD CONSTRAINT chk_stripe_subscription_tier
      CHECK (tier IN ('light', 'full'));
    """)
  }
}
