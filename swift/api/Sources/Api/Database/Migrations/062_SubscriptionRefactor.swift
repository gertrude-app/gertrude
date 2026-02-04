import FluentSQL

struct SubscriptionRefactor: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    // Step 1: Create new enums
    try await sql.execute("""
      CREATE TYPE parent.subscription_tier AS ENUM ('light', 'full');
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

    // Step 2: Add new columns to parent.parents
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN email_verified_at TIMESTAMP WITH TIME ZONE;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
    """)

    // Step 3: Create parent.subscriptions table (without constraints initially)
    try await sql.execute("""
      CREATE TABLE parent.subscriptions (
        id UUID NOT NULL,
        parent_id UUID NOT NULL,
        tier parent.subscription_tier NOT NULL,
        billing_status parent.billing_status,
        stripe_id TEXT,
        is_legacy_price BOOLEAN NOT NULL DEFAULT false,
        trial_started_at TIMESTAMP WITH TIME ZONE,
        status_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.subscriptions
      ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.subscriptions
      ADD CONSTRAINT uq_subscriptions_parent_id UNIQUE (parent_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.subscriptions
      ADD CONSTRAINT fk_subscriptions_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)

    // Step 4: Migrate data - set email_verified_at for verified users
    try await sql.execute("""
      UPDATE parent.parents
      SET email_verified_at = created_at
      WHERE subscription_status != 'pendingEmailVerification';
    """)

    // Step 5: Set deleted_at for pendingAccountDeletion users (30 days from now)
    try await sql.execute("""
      UPDATE parent.parents
      SET deleted_at = NOW() + INTERVAL '30 days'
      WHERE subscription_status = 'pendingAccountDeletion';
    """)

    // Step 6: Migrate to subscriptions table
    // 6a: complimentary -> tier=full, billing_status=NULL, distantFuture expiration
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        NULL,
        subscription_id,
        monthly_price = 500,
        NULL,
        '3000-01-01 00:00:00+00'::TIMESTAMP WITH TIME ZONE,
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'complimentary';
    """)

    // 6b: trialing -> tier=full, billing_status=trialing
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        'trialing'::parent.billing_status,
        subscription_id,
        monthly_price = 500,
        created_at,
        COALESCE(subscription_status_expiration, NOW() + INTERVAL '21 days'),
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'trialing';
    """)

    // 6c: trialExpiringSoon -> tier=full, billing_status=trialExpiringSoon
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        'trialExpiringSoon'::parent.billing_status,
        subscription_id,
        monthly_price = 500,
        created_at,
        COALESCE(subscription_status_expiration, NOW() + INTERVAL '3 days'),
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'trialExpiringSoon';
    """)

    // 6d: paid -> tier=full, billing_status=paid
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        'paid'::parent.billing_status,
        subscription_id,
        monthly_price = 500,
        created_at,
        COALESCE(subscription_status_expiration, NOW() + INTERVAL '33 days'),
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'paid';
    """)

    // 6e: overdue WITH stripe subscription -> tier=full, billing_status=overdue
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        'overdue'::parent.billing_status,
        subscription_id,
        monthly_price = 500,
        created_at,
        COALESCE(subscription_status_expiration, NOW() + INTERVAL '14 days'),
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'overdue'
        AND subscription_id IS NOT NULL;
    """)

    // 6e2: overdue WITHOUT stripe subscription (trial-expirers) -> tier=full, billing_status=trialExpired
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        'trialExpired'::parent.billing_status,
        NULL,
        monthly_price = 500,
        created_at,
        COALESCE(subscription_status_expiration, NOW() + INTERVAL '7 days'),
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'overdue'
        AND subscription_id IS NULL;
    """)

    // 6f: unpaid -> tier=full, billing_status=unpaid
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        'unpaid'::parent.billing_status,
        subscription_id,
        monthly_price = 500,
        created_at,
        COALESCE(subscription_status_expiration, NOW() + INTERVAL '365 days'),
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'unpaid';
    """)

    // 6g: pendingAccountDeletion -> tier=full, billing_status=unpaid
    try await sql.execute("""
      INSERT INTO parent.subscriptions (
        id, parent_id, tier, billing_status, stripe_id, is_legacy_price,
        trial_started_at, status_expires_at, created_at, updated_at
      )
      SELECT
        gen_random_uuid(),
        id,
        'full'::parent.subscription_tier,
        'unpaid'::parent.billing_status,
        subscription_id,
        monthly_price = 500,
        created_at,
        NOW(),
        created_at,
        NOW()
      FROM parent.parents
      WHERE subscription_status = 'pendingAccountDeletion';
    """)

    // Step 7: Add constraints to subscriptions table (after data migration)
    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      ADD CONSTRAINT stripe_id_required_for_paid_status CHECK (
        billing_status IS NULL
        OR billing_status IN ('trialing', 'trialExpiringSoon', 'trialExpired', 'unpaid')
        OR stripe_id IS NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      ADD CONSTRAINT trial_status_requires_full_plan CHECK (
        billing_status IS NULL
        OR billing_status NOT IN ('trialing', 'trialExpiringSoon', 'trialExpired')
        OR tier = 'full'
      );
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      ADD CONSTRAINT trialing_requires_trial_started CHECK (
        billing_status IS NULL
        OR billing_status NOT IN ('trialing', 'trialExpiringSoon')
        OR trial_started_at IS NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      ADD CONSTRAINT complimentary_requires_full_plan CHECK (
        billing_status IS NOT NULL
        OR tier = 'full'
      );
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      ADD CONSTRAINT light_tier_requires_stripe_id CHECK (
        tier = 'full'
        OR stripe_id IS NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      ADD CONSTRAINT trial_status_forbids_stripe_id CHECK (
        billing_status IS NULL
        OR billing_status NOT IN ('trialing', 'trialExpiringSoon', 'trialExpired')
        OR stripe_id IS NULL
      );
    """)

    // Step 8: Drop old columns from parent.parents
    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN subscription_status;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN subscription_status_expiration;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN subscription_id;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN monthly_price;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN trial_period_days;
    """)

    // Step 9: Drop old enum
    try await sql.execute("""
      DROP TYPE public.enum_parent_subscription_status;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    // Recreate old enum
    try await sql.execute("""
      CREATE TYPE public.enum_parent_subscription_status AS ENUM (
        'pendingEmailVerification',
        'trialing',
        'trialExpiringSoon',
        'overdue',
        'paid',
        'unpaid',
        'pendingAccountDeletion',
        'complimentary'
      );
    """)

    // Add old columns back to parent.parents
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN subscription_status public.enum_parent_subscription_status
        NOT NULL DEFAULT 'pendingEmailVerification';
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN subscription_status_expiration TIMESTAMP WITH TIME ZONE;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN subscription_id TEXT;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN monthly_price INTEGER NOT NULL DEFAULT 1000;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN trial_period_days INTEGER NOT NULL DEFAULT 21;
    """)

    // Migrate data back from subscriptions to parents
    // complimentary (billing_status IS NULL)
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'complimentary',
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status IS NULL;
    """)

    // trialing
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'trialing',
        subscription_status_expiration = s.status_expires_at,
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status = 'trialing';
    """)

    // trialExpiringSoon
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'trialExpiringSoon',
        subscription_status_expiration = s.status_expires_at,
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status = 'trialExpiringSoon';
    """)

    // paid
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'paid',
        subscription_status_expiration = s.status_expires_at,
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status = 'paid';
    """)

    // overdue
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'overdue',
        subscription_status_expiration = s.status_expires_at,
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status = 'overdue';
    """)

    // trialExpired -> overdue (best match in old schema)
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'overdue',
        subscription_status_expiration = s.status_expires_at,
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status = 'trialExpired';
    """)

    // unpaid (but not pending deletion)
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'unpaid',
        subscription_status_expiration = s.status_expires_at,
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status = 'unpaid'
        AND p.deleted_at IS NULL;
    """)

    // pendingAccountDeletion (unpaid with deleted_at set)
    try await sql.execute("""
      UPDATE parent.parents p
      SET
        subscription_status = 'pendingAccountDeletion',
        subscription_status_expiration = s.status_expires_at,
        subscription_id = s.stripe_id,
        monthly_price = CASE WHEN s.is_legacy_price THEN 500 ELSE 1000 END
      FROM parent.subscriptions s
      WHERE s.parent_id = p.id
        AND s.billing_status = 'unpaid'
        AND p.deleted_at IS NOT NULL;
    """)

    // Parents without subscriptions -> pendingEmailVerification (email_verified_at IS NULL)
    // Already have default value, just need to clear it for verified users without subscription
    // Actually the default handles this

    // Drop new columns from parent.parents
    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN email_verified_at;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN deleted_at;
    """)

    // Drop subscriptions table
    try await sql.execute("""
      DROP TABLE parent.subscriptions;
    """)

    // Drop new enums
    try await sql.execute("""
      DROP TYPE parent.billing_status;
    """)

    try await sql.execute("""
      DROP TYPE parent.subscription_tier;
    """)

    // Remove the default we added
    try await sql.execute("""
      ALTER TABLE parent.parents
      ALTER COLUMN subscription_status DROP DEFAULT;
    """)
  }
}
