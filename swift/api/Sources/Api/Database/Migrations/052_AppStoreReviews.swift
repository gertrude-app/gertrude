import FluentSQL

struct AppStoreReviews: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("CREATE SCHEMA appstore;")

    try await sql.execute("""
      CREATE TABLE appstore.reviews (
        id uuid NOT NULL,
        apple_id text NOT NULL,
        app text NOT NULL CHECK (app IN ('blocker', 'podcasts')),
        rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
        title text,
        body text NOT NULL,
        reviewer_nickname text NOT NULL,
        territory varchar(8) NOT NULL,
        review_created_at timestamp with time zone NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY appstore.reviews
      ADD CONSTRAINT appstore_reviews_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX appstore_reviews_apple_id_idx ON appstore.reviews (apple_id);
    """)

    try await sql.execute("""
      CREATE TABLE appstore.rating_snapshots (
        id uuid NOT NULL,
        app text NOT NULL CHECK (app IN ('blocker', 'podcasts')),
        average_rating double precision NOT NULL,
        total_count integer NOT NULL,
        review_count integer NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY appstore.rating_snapshots
      ADD CONSTRAINT appstore_rating_snapshots_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE INDEX appstore_rating_snapshots_app_created_at_idx
      ON appstore.rating_snapshots (app, created_at DESC);
    """)

    try await sql.execute("""
      CREATE TABLE appstore.rating_events (
        id uuid NOT NULL,
        app text NOT NULL CHECK (app IN ('blocker', 'podcasts')),
        stars integer NOT NULL CHECK (stars >= 1 AND stars <= 5),
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY appstore.rating_events
      ADD CONSTRAINT appstore_rating_events_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE INDEX appstore_rating_events_app_idx ON appstore.rating_events (app);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE appstore.rating_events;")
    try await sql.execute("DROP TABLE appstore.rating_snapshots;")
    try await sql.execute("DROP TABLE appstore.reviews;")
    try await sql.execute("DROP SCHEMA appstore;")
  }
}
