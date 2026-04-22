# Maintenance

## CI Files-Changed Dependencies

The CI workflows use path-based filtering to skip unnecessary jobs when only certain parts
of the monorepo change. These filters must be kept in sync with actual package
dependencies.

### Workflow Files

- `.github/workflows/swift-ci.yml` - main swift monorepo CI (includes macapp, iosapp,
  podcasts, api, libs)
- `.github/workflows/web-ci.yml` - web monorepo CI

### Where Dependencies Are Expressed

#### swift-ci.yml

The `files-changed` job defines path filters for selective job execution:

```yaml
files-changed:
  outputs:
    macapp: ... # triggers macapp-lib job
    iosapp: ... # triggers iosapp-lib job
    podcasts: ... # triggers podcasts-lib job
    libs: ... # triggers linux-build-libs-* and linux-lib-test-* jobs
    api: ... # triggers linux-api-build and linux-api-test jobs
    swift: ... # triggers swift-lint and xml-lint jobs
```

Each filter lists the directories that should trigger that job. For example, `macapp`
includes `swift/pairql-macapp/**` because macapp depends on pairql-macapp.

#### web-ci.yml

The `files-changed` job defines:

```yaml
files-changed:
  outputs:
    appviews: ... # triggers appviews-comment job
    dashboard: ... # triggers dashboard job
    site: ... # triggers site job
    storybook: ... # triggers storybook job
```

Note: The `check` job runs on all web changes without filtering.

### Periodic Maintenance Steps

1. **Review Package.swift files** - Check each package's dependencies array:

   ```bash
   grep -r "\.package(path:" swift/*/Package.swift
   grep -r "\.package(path:" swift/*/App/Package.swift
   grep -r "\.package(path:" swift/*/lib-*/Package.swift
   ```

2. **Compare with CI filters** - Ensure each `files-changed` filter includes all
   transitive dependencies. If package A depends on package B, and B depends on C, then
   A's filter should include both B and C.

3. **Check for new packages** - If a new swift package is added:

   - Add it to the appropriate `libs` filter if it's a shared library
   - Add it to `api` filter if the API depends on it
   - Update app filters (macapp, iosapp) if they depend on it

4. **Check for new web packages** - If a new web package is added:

   - Determine which apps depend on it
   - Add to appropriate filters (dashboard, site, storybook)

5. **Check for moved/renamed packages** - If a package path changes, update filters
   accordingly.

## Agent/LLM-Facing Content

Hand-authored content that describes the product, routes, or repo layout to external
agents/crawlers. None of this is generated — all of it drifts silently as the product
evolves. Review periodically (e.g., after any marketing-site restructure, product launch,
or major repo reorganization).

### `web/site/public/llms.txt`

The llms.txt index served at `https://gertrude.app/llms.txt`. Describes products, pricing,
key URLs, and positioning for AI crawlers. Drifts whenever:

- Pricing changes (`$10/month`, `$10/year`, trial lengths are all baked in as prose).
- A product gains or loses a marketing page.
- Product positioning or audience language changes.
- New top-level marketing URLs are added (or existing ones move/redirect).

### `web/site/app/sitemap.tsx` — `STATIC_ROUTES`

Hardcoded list of non-blog, non-docs marketing routes. Blog posts and docs slugs are
auto-discovered from the filesystem, but top-level marketing pages are not. Drifts
whenever a new marketing route is added under `web/site/app/` (e.g., a new product landing
page, a pricing page, a press kit). Audit against the actual route tree.

### `web/site/_redirects`

Two drift-prone buckets inside this file:

1. **"common-path agent hits" block** — catches URLs agents guess at (`/ios`, `/about`,
   `/privacy`, etc.). If a new product launches or a new common guess emerges from 404
   logs, add it here.
2. **macOS user-management video redirects** (`/cu-*`, `/du-*`, `/su-*`) — each suffix
   maps to a specific macOS version (cl/bs/mr/vt/sn/sq/th). When Apple ships a new macOS
   version, a new suffix and YouTube URL need to be added, and the comment
   `# CREATE MACOS USER (current: X.Y.Z+)` version marker updated.

### `CLAUDE.md` files (repo root + per-app)

Current set (as of this writing): `./CLAUDE.md`, `./web/CLAUDE.md`, `./swift/CLAUDE.md`,
`./web/supervise/CLAUDE.md`, `./swift/podcasts/CLAUDE.md`. These describe paths, ports,
commands, and architecture to Claude Code. Drifts when:

- Apps are added/removed/renamed (e.g., a new `web/*` app or `swift/*` package).
- Dev commands change (`just` recipes renamed, ports moved).
- Directory structure moves (e.g., `web/dash` → `web/dash/app`).

### `docs/support/*.md` — product overview docs

`product-overview.md`, `mac-app.md`, `ios-app.md`, `gertrude-am.md`. These are the
agent-facing source of truth for how the product works. Drift whenever features ship, are
renamed, or are removed. Review after any significant feature launch.

### `docs/*.md` — code-describing docs

`codegen.md`, `templated-emails.md`, `ios-block-rule-analysis.md`, `ios-supervision.md`,
`pairql.md` (in `swift/docs/`). These describe code and will rot if the code they describe
is refactored. When touching any of the systems they describe, update the doc in the same
PR.
