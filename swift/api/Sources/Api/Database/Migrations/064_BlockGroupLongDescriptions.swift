import FluentSQL

struct BlockGroupLongDescriptions: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_groups
      ADD COLUMN long_description text NOT NULL DEFAULT '';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'Blocks the 20 most common ad providers, including Google ads, in all browsers and apps. Does not guarantee to block all ads, but should make a noticeable difference.'
      WHERE name = 'Ads';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'Blocks certain cloud-based AI features like image recognition. For example, the iOS 18 feature where an item in a photo can be long-pressed, identified, and searched for online.'
      WHERE name = 'AI features';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'Eliminates all images for apps in the App Store, and in other places where the App Store appears, like in the Messages texting app.'
      WHERE name = 'App store images';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'Apple Maps business listings show photos uploaded by customers and businesses, and for certain types of businesses, these can be explicit. This group blocks all images from within Apple Maps.'
      WHERE name = 'Apple Maps images';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'Certain parts of iOS (including the Settings app) contain links to the apple.com website. It is possible to view these pages and from there follow links to other parts of the web. This group blocks this access.'
      WHERE name = 'apple.com';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'Blocks viewing and searching for GIFs in the #images feature of Apple''s texting app, plus in other common messaging apps like WhatsApp, Skype, and Signal.'
      WHERE name = 'GIFs';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'The built in search bar in iOS (called Spotlight) allows searching for information and images from the internet. This group stops all spotlight internet searches. On-device data searches are not blocked.'
      WHERE name = 'Spotlight';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'This group attempts to block some of aspects of the WhatsApp app, including the media channels. It is experimental, and does not guarantee by any means that the app will be safe for children, but it does reduce some risks.'
      WHERE name = 'WhatsApp';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET long_description = 'Blocks images displayed in the Spotify app, including album artwork, artist photos, and playlist covers. This helps prevent exposure to potentially explicit or inappropriate imagery while still allowing music playback.'
      WHERE name = 'Spotify images';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_groups
      DROP COLUMN IF EXISTS long_description;
    """)
  }
}
