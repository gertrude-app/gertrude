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
   # fast: render with sample data to a screenshot, no API needed
   just swift preview-email {alias} [--dark] [--mobile]

   # or live in the browser (needs the API running, renders literal {{vars}})
   just swift api
   just swift web-email admin-{template-name}
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

| Command                                  | Purpose                            |
| ---------------------------------------- | ---------------------------------- |
| `just swift preview-email {alias}`       | Screenshot w/ sample data (no API) |
| `just swift send-email admin-{template}` | Send test email                    |
| `just swift web-email admin-{template}`  | Preview HTML in browser            |
| `just swift sync-email-templates`        | Sync all templates                 |

### Preview with sample data (no API)

`just swift preview-email {alias} [--dark] [--mobile]` renders a template populated with
sample data and writes an HTML file + screenshot to a temp dir (path is printed). Unlike
`web-email`, it needs no running API and shows real content instead of literal `{{vars}}`
— handy for fast visual iteration and for agents (who can read the PNG).

The script lives at `web/storybook/visual-tests/preview-email.mts` (that package has the
puppeteer dependency). It's a plain `.mts` run by `node` via type-stripping — no `ts-node`.
Its `SAMPLES` map mirrors the sample models in `TestEmail.swift`, which is the source of
truth — when you add a template, add a `SAMPLES` entry there too (see the next section).

## Adding a New Template

1. Create `Templates/{NewName}/template.html` and `template.md`
2. Add Swift model struct to `TemplateEmails.swift`
3. Add case to `Email+Types.swift`
4. Add test alias to `TestEmail.swift`, plus a matching `SAMPLES` entry in
   `web/storybook/visual-tests/preview-email.mts` (enables `just swift preview-email`)
5. Register it in `SyncPostmark.swift`'s `syncAll()` with `syncTemplate(NewName.self)` —
   easy to miss; without it the sync silently skips your template
6. Create the template in Postmark web UI first (the sync tool only updates, doesn't
   create):
   - Go to Templates → New Template
   - Set the alias to match (e.g. `screen-time-warning`)
   - No layout, no content needed—first sync will set everything correctly
7. Run `just swift sync-email-templates`

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

### Gmail strips `margin`/`inline-block` gaps — the preview won't catch it

`just swift preview-email` renders in Chromium, which faithfully draws CSS `margin` and
`inline-block` spacing. **Gmail silently drops both on small elements**, so a layout that
relies on them looks perfect in the preview but **merges/clips in Gmail** (e.g. a row of
`inline-block` tiles collapses into one bar; margin-stacked lines smear together).

```
✗  <span style="display:inline-block; margin:0 5px 0 0">  → gaps vanish in Gmail
✓  <table cellspacing="5"><tr><td>…</td><td>…</td></tr>   → real gaps everywhere
```

Space inner layout with **table cell-spacing / spacer rows/cells**, not margins. Treat the
preview as layout-correctness only — for Gmail-specific rendering, send a real test
(`?for=<email>`) and inspect in Gmail itself.

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
