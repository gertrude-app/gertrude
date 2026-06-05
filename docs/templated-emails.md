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

## Gotchas

### Optional vars in a section: use `{{.}}`, not `{{var}}`

Mustachio makes the section value the context, so `{{var}}` inside `{{#var}}`
resolves against the string and renders **empty**:

```
✗  {{#redirect}}?redirect={{redirect}}{{/redirect}}   → "?redirect="
✓  {{#redirect}}?redirect={{.}}{{/redirect}}          → "?redirect=<value>"
```

Fails silently, and only when the var is non-nil — a nil/empty test renders
identically to a correct one, so always test with the value populated.

### Render without sending

`/templates/validate` renders a body against a test model (nothing sent, no stored
template touched):

```bash
KEY=$(grep '^POSTMARK_API_KEY=' swift/api/.env | cut -d= -f2- | tr -d '"')
curl -s https://api.postmarkapp.com/templates/validate \
  -H "X-Postmark-Server-Token: $KEY" -H "Content-Type: application/json" \
  -d '{"HtmlBody":"<p>x</p>","TextBody":"{{#redirect}}?redirect={{.}}{{/redirect}}","TestRenderModel":{"redirect":"abc"}}' \
  | python3 -c "import sys,json;print(repr(json.load(sys.stdin)['TextBody']['RenderedContent']))"
```
