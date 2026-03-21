import FluentSQL

struct BlockGroupImageSlugs: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_groups
      ADD COLUMN image_slug text;
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'MessagesGIFs'
      WHERE id = '087628b2-742c-4164-a3cc-717c4ac72c1a';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'MapsImages'
      WHERE id = 'baecbdda-49c0-43ec-a931-777810f34c13';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'AIFeatures'
      WHERE id = 'c15351df-ff54-4b75-8f7e-2b522a3a0dae';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'AppStoreImages'
      WHERE id = '283a29ec-13eb-4bd3-9211-eb920bd85158';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'SpotlightSearch'
      WHERE id = 'df7fb156-488a-497b-aa12-c585d3fa4e6c';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'AdBlocking'
      WHERE id = '1ea5f1b8-1b14-4894-9913-56cfee98bd48';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'BadWhatsAppFeatures'
      WHERE id = '8e337c3c-2efb-404a-8eb3-781661231844';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'AppleWebsite'
      WHERE id = '9cd776c0-f1a6-43c2-861b-f6c6ec8cf513';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'SpotifyImages'
      WHERE id = 'ee242fc6-07c7-4694-a3ce-0323b0ddc1fe';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups SET image_slug = 'AppleMusicImages'
      WHERE id = '236c92c9-a06c-4f68-9f1a-74e76163ae07';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_groups
      DROP COLUMN IF EXISTS image_slug;
    """)
  }
}
