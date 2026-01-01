# Templated Emails

Gertrude uses Postmark for sending templated emails. Templates are stored locally and
synced to Postmark.

## Template Locations

```
swift/api/Sources/Api/Email/
├── Templates/              # Email template content
│   └── {TemplateName}/
│       ├── template.html   # HTML version
│       └── template.md     # Plain text version
├── Layouts/                # Shared layouts (base, top-logo)
├── TemplateEmails.swift    # Swift models (subject, variables)
└── SyncPostmark.swift      # Sync tool
```

## Updating a Template

1. Edit the template files in `Templates/{TemplateName}/`:
   - `template.html` for HTML content
   - `template.md` for plain text content

2. If changing the subject or variables, update `TemplateEmails.swift`

3. Preview changes locally:
   ```bash
   just api                              # start the API server
   just web-email admin-{template-name}  # preview in browser
   ```

4. Test sending:
   ```bash
   just send-email admin-{template-name}  # sends to TEST_EMAIL_RECIPIENT
   ```

5. Sync to Postmark:
   ```bash
   just sync-email-templates
   ```

## Template Variables

Templates use Postmark's `{{variable}}` syntax. Variables are defined in the Swift model's
`templateModel` property in `TemplateEmails.swift`.

## Available Test Commands

| Command                                 | Purpose                    |
| --------------------------------------- | -------------------------- |
| `just send-email admin-{template}`      | Send test email            |
| `just web-email admin-{template}`       | Preview HTML in browser    |
| `just sync-email-templates`             | Sync all templates         |

## Adding a New Template

1. Create `Templates/{NewName}/template.html` and `template.md`
2. Add Swift model struct to `TemplateEmails.swift`
3. Add case to `Email+Types.swift`
4. Add test alias to `TestEmail.swift`
5. Run `just sync-email-templates`
