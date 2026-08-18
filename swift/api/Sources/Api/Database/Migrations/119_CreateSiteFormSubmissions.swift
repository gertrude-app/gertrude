import FluentSQL

struct CreateSiteFormSubmissions: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE system.site_form_submissions (
        id uuid PRIMARY KEY,
        form text NOT NULL CONSTRAINT chk_site_form_submissions_form
          CHECK (form IN ('contact', 'lockdownGuide', 'fiveThings')),
        app text CONSTRAINT chk_site_form_submissions_app
          CHECK (app IN ('mac', 'blocker', 'podcasts', 'music', 'unsure')),
        name text NOT NULL,
        email text NOT NULL,
        subject text,
        message text NOT NULL,
        parent_id uuid REFERENCES parent.parents(id) ON DELETE SET NULL,
        assignee text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_site_form_submissions_subject
          CHECK (form <> 'contact' OR subject IS NOT NULL)
      );
    """)

    try await sql.execute("""
      CREATE INDEX idx_site_form_submissions_email
        ON system.site_form_submissions (lower(email));
    """)

    try await sql.execute("""
      CREATE INDEX idx_site_form_submissions_created_at
        ON system.site_form_submissions (created_at DESC);
    """)

    try await sql.execute("""
      CREATE INDEX idx_site_form_submissions_parent_id
        ON system.site_form_submissions (parent_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE IF EXISTS system.site_form_submissions;
    """)
  }
}
