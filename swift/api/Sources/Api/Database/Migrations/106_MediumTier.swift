import FluentSQL

struct MediumTier: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP CONSTRAINT chk_stripe_subscription_tier;
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD CONSTRAINT chk_stripe_subscription_tier
      CHECK (tier IN ('light', 'medium', 'full'));
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      RENAME CONSTRAINT light_tier_requires_stripe_id TO non_full_tier_requires_stripe_id;
    """)

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      DROP CONSTRAINT billing_identities_last_paid_tier_check;
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
      DROP CONSTRAINT billing_identities_last_paid_tier_check;
    """)

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      ADD CONSTRAINT billing_identities_last_paid_tier_check
      CHECK (last_paid_tier IS NULL OR last_paid_tier IN ('light', 'full'));
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      RENAME CONSTRAINT non_full_tier_requires_stripe_id TO light_tier_requires_stripe_id;
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP CONSTRAINT chk_stripe_subscription_tier;
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD CONSTRAINT chk_stripe_subscription_tier
      CHECK (tier IN ('light', 'full'));
    """)
  }
}
