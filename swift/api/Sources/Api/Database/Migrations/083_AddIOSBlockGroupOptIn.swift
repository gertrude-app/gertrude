import FluentSQL
import Foundation

struct AddIOSBlockGroupOptIn: GertieMigration {
  let whatsAppId = CreateBlockGroups.GroupIds().whatsAppFeatures

  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_groups
      ADD COLUMN opt_in boolean NOT NULL DEFAULT false;
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups
      SET
        opt_in = true,
        description = 'Partial WhatsApp blocking. WARNING: likely breaks voice/video calls.',
        long_description = 'Aggressive WhatsApp blocking, including channel media, in-app browsing, Meta AI traffic, and most non-WhatsApp traffic the app touches. WARNING: likely breaks voice and video calls, and may cause other in-app features to stop working. Makes the app safer, but not fully safe.',
        updated_at = NOW()
      WHERE id = '\(uuid: self.whatsAppId)';
    """)

    try await sql.execute("""
      DELETE FROM iosapp.block_rules
      WHERE group_id = '\(uuid: self.whatsAppId)';
    """)

    for (ruleId, ruleJson, comment) in Self.whatsAppRules {
      try await sql.execute("""
        INSERT INTO iosapp.block_rules (id, device_id, rule, group_id, comment, created_at, updated_at)
        VALUES (
          '\(uuid: ruleId)',
          NULL,
          '\(unsafeRaw: ruleJson)'::JSONB,
          '\(uuid: self.whatsAppId)',
          '\(unsafeRaw: comment)',
          NOW(),
          NOW()
        );
      """)
    }
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DELETE FROM iosapp.block_rules
      WHERE group_id = '\(uuid: self.whatsAppId)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_groups
      SET
        description = 'Block WhatsApp channels media and in-app web browsing.',
        long_description = 'Blocks images and videos from WhatsApp channels, and blocks the in-app web browser that opens when tapping links inside WhatsApp. Does not affect messaging or voice/video calls. Experimental — does not guarantee the app is safe for children, but reduces some risks.',
        updated_at = NOW()
      WHERE id = '\(uuid: self.whatsAppId)';
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.block_groups
      DROP COLUMN IF EXISTS opt_in;
    """)
  }

  // Restores the pre-2026-04-16 WhatsApp block group exactly: the 3 rules
  // with original UUIDs, JSON, and comments as captured in the production
  // backup at 2026-03-15. The 2026-04-16 weakening dropped these from the
  // group; we replace the post-weakening pair (CDN + in-app browser) with
  // the original three, since the historical `unless` and `media` rules
  // dominate them., xref: a9712745
  static let whatsAppRules: [(UUID, String, String)] = [
    (
      UUID(uuidString: "c9252bcd-525b-4a62-a987-de52d40967c0")!,
      #"{"case":"targetContains","value":"media.fosu2-1.fna.whatsapp.net"}"#,
      "channels media images",
    ),
    (
      UUID(uuidString: "1c64c75a-eac2-4daf-a139-9855a85bbc37")!,
      #"{"a":{"case":"targetContains","value":"whatsapp.net"},"b":{"case":"targetContains","value":"media"},"case":"both"}"#,
      "media channel",
    ),
    (
      UUID(uuidString: "779e8be5-4704-41f7-9648-d4db7340814b")!,
      #"{"case":"unless","rule":{"case":"bundleIdContains","value":"net.whatsapp.WhatsApp"},"negatedBy":[{"case":"hostnameEndsWith","value":"whatsapp.net"}]}"#,
      "loading other content",
    ),
  ]
}
