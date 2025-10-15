import SQLiteData

enum Migrations {
  @Sendable static func m2025_10_13(_ db: Database) throws {
    try #sql(
      """
      ALTER TABLE events
      ADD COLUMN apiId TEXT;
      """
    ).execute(db)
    try #sql(
      """
      ALTER TABLE events
      ADD COLUMN kind TEXT NOT NULL
        CHECK (kind IN ('error', 'unexpected', 'info', 'debug', 'subscription'))
        DEFAULT 'debug';
      """
    ).execute(db)
    try #sql(
      """
      ALTER TABLE events
      RENAME COLUMN name TO label;
      """
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
      """
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
      """
    ).execute(db)
  }

  @Sendable static func m2025_10_08(_ db: Database) throws {
    try #sql(
      """
      ALTER TABLE episodes
      ADD COLUMN isArchived INTEGER NOT NULL
        CHECK (isArchived IN (0, 1)) DEFAULT 0;
      """
    ).execute(db)
    try #sql(
      """
      ALTER TABLE shows
      ADD COLUMN sort TEXT NOT NULL
        CHECK (sort IN ('newestToOldest', 'oldestToNewest')) DEFAULT 'newestToOldest';
      """
    ).execute(db)
  }

  @Sendable static func m2025_10_07(_ db: Database) throws {
    try #sql(
      """
      DROP TABLE miscs;
      """
    ).execute(db)
    try #sql(
      """
      CREATE TABLE nowPlaying (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        episodeId INTEGER,
        minimized INTEGER NOT NULL CHECK (minimized IN (0, 1)),
        isPlaying INTEGER NOT NULL CHECK (isPlaying IN (0, 1)),
        nextDownloaded INTEGER NOT NULL CHECK (nextDownloaded IN (0, 1)),
        updatedAt TEXT NOT NULL
      ) STRICT;
      """
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
      """
    ).execute(db)
  }

  @Sendable static func preRelease(_ db: Database) throws {
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
         updatedAt TEXT NOT NULL,
         createdAt TEXT NOT NULL
       ) STRICT;
      """
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
         lastPlayedAt TEXT,
         completedAt TEXT,
         downloadedAt TEXT,
         updatedAt TEXT NOT NULL,
         createdAt TEXT NOT NULL,
         FOREIGN KEY (showId) REFERENCES shows (id) ON DELETE CASCADE
       ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
      CREATE TABLE miscs (
        id TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL,
        rowId INTEGER,
        updatedAt TEXT NOT NULL,
        createdAt TEXT NOT NULL
      ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
      CREATE TABLE events (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        detail TEXT,
        createdAt TEXT NOT NULL
      ) STRICT;
      """
    ).execute(db)
    try #sql(
      """
      CREATE TABLE pinAttempts (
        id INTEGER PRIMARY KEY,
        success INTEGER NOT NULL CHECK (success IN (0, 1)),
        createdAt TEXT NOT NULL
      ) STRICT;
      """
    ).execute(db)
  }
}
