import FluentSQL

struct PgEnumsToText: GertieMigration {
  let statusColumns = [
    ("macapp.suspend_filter_requests", "chk_macapp_suspend_filter_request_status"),
    ("macapp.unlock_requests", "chk_unlock_request_status"),
    ("blocker_app.suspend_filter_requests", "chk_blocker_suspend_filter_request_status"),
  ]

  let channelColumns = [
    ("macapp.releases", "channel", "chk_release_channel"),
    ("parent.computers", "app_release_channel", "chk_computer_app_release_channel"),
  ]

  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP CONSTRAINT light_tier_requires_stripe_id;
    """)
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ALTER COLUMN tier TYPE text USING tier::text;
    """)
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD CONSTRAINT chk_stripe_subscription_tier CHECK (tier IN ('light', 'full'));
    """)
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD CONSTRAINT light_tier_requires_stripe_id
      CHECK (tier = 'full' OR stripe_id IS NOT NULL);
    """)

    for (table, constraint) in self.statusColumns {
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ALTER COLUMN status TYPE text USING status::text;
      """)
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ADD CONSTRAINT \(unsafeRaw: constraint)
        CHECK (status IN ('pending', 'accepted', 'rejected'));
      """)
    }

    for (table, column, constraint) in self.channelColumns {
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ALTER COLUMN \(unsafeRaw: column) TYPE text USING \(unsafeRaw: column)::text;
      """)
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ADD CONSTRAINT \(unsafeRaw: constraint)
        CHECK (\(unsafeRaw: column) IN ('stable', 'beta', 'canary'));
      """)
    }

    try await sql.execute("DROP TYPE parent.subscription_tier;")
    try await sql.execute("DROP TYPE public.enum_shared_request_status;")
    try await sql.execute("DROP TYPE public.enum_release_channels;")
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TYPE parent.subscription_tier AS ENUM ('light', 'full');
    """)
    try await sql.execute("""
      CREATE TYPE public.enum_shared_request_status AS ENUM
      ('pending', 'accepted', 'rejected');
    """)
    try await sql.execute("""
      CREATE TYPE public.enum_release_channels AS ENUM
      ('stable', 'beta', 'canary');
    """)

    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP CONSTRAINT chk_stripe_subscription_tier;
    """)
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      DROP CONSTRAINT light_tier_requires_stripe_id;
    """)
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ALTER COLUMN tier TYPE parent.subscription_tier
      USING tier::parent.subscription_tier;
    """)
    try await sql.execute("""
      ALTER TABLE parent.stripe_subscriptions
      ADD CONSTRAINT light_tier_requires_stripe_id
      CHECK (tier = 'full'::parent.subscription_tier OR stripe_id IS NOT NULL);
    """)

    for (table, constraint) in self.statusColumns {
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        DROP CONSTRAINT \(unsafeRaw: constraint);
      """)
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ALTER COLUMN status TYPE public.enum_shared_request_status
        USING status::public.enum_shared_request_status;
      """)
    }

    for (table, column, constraint) in self.channelColumns {
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        DROP CONSTRAINT \(unsafeRaw: constraint);
      """)
      try await sql.execute("""
        ALTER TABLE \(unsafeRaw: table)
        ALTER COLUMN \(unsafeRaw: column) TYPE public.enum_release_channels
        USING \(unsafeRaw: column)::public.enum_release_channels;
      """)
    }
  }
}
