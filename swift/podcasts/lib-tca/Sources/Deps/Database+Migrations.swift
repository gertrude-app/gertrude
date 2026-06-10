import SQLiteData

enum Migrations {
  @Sendable static func release(_ db: Database) throws {
    try #sql(
      """
      CREATE TABLE shows (
        id INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        author TEXT,
        description TEXT,
        feedUrl TEXT NOT NULL UNIQUE,
        websiteUrl TEXT,
        artworkUrl TEXT,
        showArtwork INTEGER NOT NULL CHECK (showArtwork IN (0, 1)),
        iTunesId INTEGER,
        sort TEXT NOT NULL
          CHECK (sort IN ('newestToOldest', 'oldestToNewest'))
          DEFAULT 'newestToOldest',
        updatedAt TEXT NOT NULL,
        createdAt TEXT NOT NULL
      ) STRICT;
      """,
    ).execute(db)
    try #sql(
      """
      CREATE TABLE episodes (
        id INTEGER PRIMARY KEY NOT NULL,
        showId INTEGER NOT NULL,
        episodeNumber INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        websiteUrl TEXT,
        audioUrl TEXT NOT NULL,
        artworkUrl TEXT,
        duration INTEGER,
        sizeInBytes INTEGER NOT NULL,
        audioType TEXT NOT NULL CHECK (audioType IN ('audio/mpeg', 'audio/x-m4a')),
        guid TEXT NOT NULL,
        pubDate TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0.0,
        isArchived INTEGER NOT NULL CHECK (isArchived IN (0, 1)) DEFAULT 0,
        lastPlayedAt TEXT,
        completedAt TEXT,
        downloadedAt TEXT,
        updatedAt TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (showId) REFERENCES shows (id) ON DELETE CASCADE
      ) STRICT;
      """,
    ).execute(db)
    try #sql(
      """
      CREATE UNIQUE INDEX idx_episodes_showId_guid ON episodes(showId, guid);
      """,
    ).execute(db)
    try #sql(
      """
      CREATE INDEX idx_episodes_showId ON episodes(showId);
      """,
    ).execute(db)
    try #sql(
      """
      CREATE INDEX idx_episodes_pubDate ON episodes(pubDate);
      """,
    ).execute(db)
    try #sql(
      """
      CREATE TABLE pinAttempts (
        id INTEGER PRIMARY KEY,
        success INTEGER NOT NULL CHECK (success IN (0, 1)),
        createdAt TEXT NOT NULL
      ) STRICT;
      """,
    ).execute(db)
    try #sql(
      """
      CREATE TABLE subscription (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        status TEXT NOT NULL
          CHECK (status IN ('trialing', 'active', 'complimentary', 'unpaid')),
        purchasePendingSince TEXT,
        expiresAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        createdAt TEXT NOT NULL
      ) STRICT;
      """,
    ).execute(db)
    try #sql(
      """
      CREATE TABLE records (
        id TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL,
        detail TEXT,
        updatedAt TEXT NOT NULL,
        createdAt TEXT NOT NULL
      ) STRICT;
      """,
    ).execute(db)
    try #sql(
      """
      CREATE TABLE events (
        id INTEGER PRIMARY KEY,
        kind TEXT NOT NULL
          CHECK (kind IN ('error', 'unexpected', 'info', 'debug', 'subscription'))
          DEFAULT 'debug',
        apiId TEXT,
        label TEXT NOT NULL,
        detail TEXT,
        createdAt TEXT NOT NULL
      ) STRICT;
      """,
    ).execute(db)
    try #sql(
      """
      CREATE TABLE IF NOT EXISTS "nowPlaying" (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        episodeId INTEGER NOT NULL REFERENCES episodes(id) ON DELETE CASCADE,
        minimized INTEGER NOT NULL CHECK (minimized IN (0, 1)),
        isPlaying INTEGER NOT NULL CHECK (isPlaying IN (0, 1)),
        nextDownloaded INTEGER NOT NULL CHECK (nextDownloaded IN (0, 1)),
        bufferedProgress REAL,
        updatedAt TEXT NOT NULL
      ) STRICT;
      """,
    ).execute(db)
    try #sql(
      """
      INSERT INTO subscription (
        id,
        status,
        purchasePendingSince,
        expiresAt,
        updatedAt,
        createdAt
      ) VALUES (
        1,
        'trialing',
        NULL,
        strftime('%Y-%m-%d %H:%M:%f', 'now', '+30 days'),
        datetime('subsec'),
        datetime('subsec')
      );
      """,
    ).execute(db)
  }

  @Sendable static func playbackRate(_ db: Database) throws {
    try #sql(
      """
      ALTER TABLE shows ADD COLUMN playbackRate REAL NOT NULL DEFAULT 1.0;
      """,
    ).execute(db)
  }

  @Sendable static func accountSubscriptionConversion(_ db: Database) throws {
    try #sql(
      """
      ALTER TABLE subscription DROP COLUMN purchasePendingSince;
      """,
    ).execute(db)
    try #sql(
      """
      ALTER TABLE subscription ADD COLUMN legacyMigrationNag INTEGER NOT NULL
        CHECK (legacyMigrationNag IN (0, 1)) DEFAULT 0;
      """,
    ).execute(db)
  }
}
