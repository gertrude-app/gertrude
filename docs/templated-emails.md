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
   just swift api                              # start the API server
   just swift web-email admin-{template-name}  # preview in browser
   ```

4. Test sending:

   ```bash
   just swift send-email admin-{template-name}  # sends to TEST_EMAIL_RECIPIENT
   ```

5. Sync to Postmark:
   ```bash
   just swift sync-email-templates
   ```

## Template Variables

Templates use Postmark's `{{variable}}` syntax. Variables are defined in the Swift model's
`templateModel` property in `TemplateEmails.swift`.

## Available Test Commands

| Command                                  | Purpose                 |
| ---------------------------------------- | ----------------------- |
| `just swift send-email admin-{template}` | Send test email         |
| `just swift web-email admin-{template}`  | Preview HTML in browser |
| `just swift sync-email-templates`        | Sync all templates      |

## Adding a New Template

1. Create `Templates/{NewName}/template.html` and `template.md`
2. Add Swift model struct to `TemplateEmails.swift`
3. Add case to `Email+Types.swift`
4. Add test alias to `TestEmail.swift`
5. Create the template in Postmark web UI first (the sync tool only updates, doesn't
   create):
   - Go to Templates → New Template
   - Set the alias to match (e.g. `screen-time-warning`)
   - No layout, no content needed—first sync will set everything correctly
6. Run `just swift sync-email-templates`
