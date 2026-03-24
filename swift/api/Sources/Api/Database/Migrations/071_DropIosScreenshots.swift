import FluentSQL
import Foundation

struct DropIosScreenshots: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.screenshots
      DROP CONSTRAINT fk_screenshots_ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      DROP COLUMN ios_device_id;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      ALTER COLUMN computer_user_id SET NOT NULL;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.screenshots
      ALTER COLUMN computer_user_id DROP NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      ADD COLUMN ios_device_id UUID;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.screenshots
      ADD CONSTRAINT fk_screenshots_ios_device_id
      FOREIGN KEY (ios_device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)
  }
}
