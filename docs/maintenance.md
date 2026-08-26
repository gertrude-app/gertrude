# Maintenance

## CI Files-Changed Dependencies

The CI workflows use path-based filtering to skip unnecessary jobs when only certain parts
of the monorepo change. These filters must be kept in sync with actual package
dependencies.

### Workflow Files

- `.github/workflows/swift-ci.yml` - main swift monorepo CI (includes macapp, iosapp,
  podcasts, api, libs)
- `.github/workflows/web-ci.yml` - web monorepo CI
- `.github/workflows/pr-body.yml` - path-scoped PR body reminders

### Where Dependencies Are Expressed

#### swift-ci.yml

The `files-changed` job defines path filters for selective job execution:

```yaml
files-changed:
  outputs:
    macapp: ... # triggers macapp-lib job
    iosapp: ... # triggers iosapp-lib job
    podcasts: ... # triggers podcasts-lib job
    music: ... # triggers music-lib job
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
    admin: ... # triggers admin job
    appviews: ... # triggers appviews-comment job
    dashboard: ... # triggers dashboard job
    site: ... # triggers site job
    storybook_v2: ... # triggers the Account/UI Storybook build
    storybook: ... # legacy Storybook job PAUSED — see below
```

Note: The `check` job runs on all web changes without filtering — it covers lint,
format-check, typecheck (via nx, across every package with a `typecheck` script), and
vitest.

The `storybook_v2` job is a build-only check for `web/storybook-v2`. Its filter includes
`web/account`, `web/ui`, and Account's transitive workspace dependencies because Storybook
v2 consumes their source, stories, styles, and static assets. It does not generate or
compare screenshots. Account itself is also built by the Cloudflare Workers integration on
every pull request.

**`web/supervise` intentionally has no dedicated `files-changed` output.** It has no build
step (`main: "./src/index.ts"`, source-only) and is consumed by the external Tauri
supervision tool, not built from this repo. The lint/format/typecheck coverage from
`check` is sufficient for the package itself. It can still appear in another app's filter
when that app imports it, such as Storybook visual coverage.

#### pr-body.yml

The `screenshot-checklist` job uses `dorny/paths-filter` to decide whether to add the
Storybook v2 screenshot checklist to the PR body. The `screenshots` filter should include
every path that can affect `web/storybook-v2/screenshots/**` when
`just update-ui-screenshots` runs.

Current scope:

- `web/storybook-v2/**` — runner, Storybook config, generated screenshots, manifest.
- `web/ui/**` — shared UI primitives/components and their stories.
- `web/account/**` — account app pages/components and their stories.
- `web/shared/**` — shared data/helpers imported by account Storybook stories.
- `web/justfile`, `web/package.json`, `web/pnpm-lock.yaml`, `web/pnpm-workspace.yaml` —
  screenshot command and dependency/workspace wiring.

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
   - Add it and its transitive dependencies to the appropriate filters (dashboard, site,
     storybook)
   - If it can affect Storybook v2 screenshots, add it to the `screenshots` filter in
     `.github/workflows/pr-body.yml`

5. **Check for moved/renamed packages** - If a package path changes, update filters
   accordingly.

## Paused: Argos Visual Regression

**Paused 2026-06-23.** Removed the `storybook` job from `web-ci.yml` — it built Storybook,
ran `just visual-test`, uploaded to [Argos](https://argos-ci.com), and opened automated
"update screenshots from CI" PRs. Too noisy (flaky diffs, agent-driven PR volume) and over
the Argos free tier.

Kept (restorable): `web/storybook/visual-tests/`, the `visual-test` / `build-storybook`
justfile recipes, the `@argos-ci/puppeteer` dep, and the `storybook` `files-changed`
output + filter. This is separate from the build-only `storybook_v2` job. To restore,
re-add the job from git history and check the `ARGOS_TOKEN` secret + branch-protection
required checks.

**Decide at the Account cutover.** When `web/account` replaces the `web/dash` dashboard,
make a real call rather than letting it sit — restore it, or delete the machinery. That's
the right forcing function because most of what the legacy Storybook covers is about to
become obsolete anyway. Deliberately not a date: there's no value in ripping it out on a
timer while the thing it covers is still shipping.

Two things to know before deleting, because "rip it all out" is not as clean as it sounds:

- **The legacy Storybook isn't only dash.** Of its ~86 stories, ~60 are dash, but the rest
  are not (`macos-app`, `site`, `shared`, `supervise`) and don't go away with the
  dashboard. Deleting the package drops those too.
- **`visual-tests/` holds non-Argos tooling wired to live recipes** —
  `export-og-images.ts` (`web/justfile`) and `preview-email.mts` (`swift/justfile`). Both
  break if the directory is deleted wholesale; they'd need rehoming first.

## Agent/LLM-Facing Content

Hand-authored content that describes the product, routes, or repo layout to external
agents/crawlers. None of this is generated — all of it drifts silently as the product
evolves. Review periodically (e.g., after any marketing-site restructure, product launch,
or major repo reorganization).

### `web/site/public/llms.txt`

The llms.txt index served at `https://gertrude.app/llms.txt`. Describes products, pricing,
positioning, and public publishing content for AI crawlers. It is comprehensive for the
publishing hierarchy: every Resources, Guides, Help, Updates, Blog, Program, and Legal
collection or detail route must be represented. Other product and marketing routes remain
a curated set of key URLs. It drifts whenever:

- Pricing changes (`$10/month`, `$10/year`, trial lengths are all baked in as prose).
- A product gains or loses a marketing page.
- Product positioning or audience language changes.
- A public publishing collection or detail route is added, moved, or retired.
- A key top-level marketing URL is added, moved, or redirected.

### `web/site/app/sitemap.tsx` — `STATIC_ROUTES`

Hardcoded list of non-article marketing routes. Publishing article slugs are
auto-discovered from the filesystem, but top-level marketing and collection pages are
not. Drifts whenever a new marketing or collection route is added under `web/site/app/`
(e.g., a product landing page, publishing index, pricing page, or press kit). Audit against
the actual route tree.

### `web/site/_redirects`

Two drift-prone buckets inside this file:

1. **"common-path agent hits" block** — catches URLs agents guess at (`/ios`, `/about`,
   `/privacy`, etc.). If a new product launches or a new common guess emerges from 404
   logs, add it here.
2. **macOS user-management video redirects** (`/cu-*`, `/du-*`, `/su-*`) — each suffix
   maps to a specific macOS version (cl/bs/mr/vt/sn/sq/th). When Apple ships a new macOS
   version, a new suffix and YouTube URL need to be added, and the comment
   `# CREATE MACOS USER (current: X.Y.Z+)` version marker updated.

### `AGENTS.md` files (repo root + per-app)

Current set (as of this writing):

- `./AGENTS.md`
- `./swift/AGENTS.md`
- `./swift/music/AGENTS.md`
- `./swift/podcasts/AGENTS.md`
- `./web/AGENTS.md`
- `./web/account/AGENTS.md`
- `./web/account/src/components/AGENTS.md`
- `./web/supervise/AGENTS.md`

Re-derive the list with `find . -name AGENTS.md -not -path "*/node_modules/*" | sort`
rather than trusting the above — new ones get added without this doc being touched.

These describe paths, ports, commands, and architecture to coding agents. Drifts when:

- Apps are added/removed/renamed (e.g., a new `web/*` app or `swift/*` package).
- Dev commands change (`just` recipes renamed, ports moved).
- Directory structure moves (e.g., `web/dash` → `web/dash/app`).

### `docs/notes/index.md` — decision-notes menu

One-line summary of every ADR-style note in `docs/notes/`. Agents researching past
decisions read this first to find the right note to load. **Drifts whenever a new note is
added or an existing one materially changes scope — append (or update) the matching entry
in the same change.**

### `.agents/skills/*/SKILL.md` — agent skills

Every skill is hand-authored, and most of them orient an agent by naming concrete things
in the repo. Those references are what rot. List the current set with `ls .agents/skills/`
rather than working from a list here, and when reviewing one, look for the reference types
that go stale silently:

- **File and directory paths** — the most common, and they move when apps get
  restructured.
- **Line-number references** (e.g. "lines 41-60 of X") — accurate when written, wrong
  after the next edit to that file, and wrong without looking wrong.
- **External URLs** as a source of truth — a third-party site can restructure or disappear
  without anything here changing.
- **Command and recipe names** — `just` recipes get renamed.
- **Filename or format contracts** — e.g. an exact asset-naming scheme the UI relies on.
- **Hand-authored inventories** — any list purporting to enumerate something that lives
  elsewhere in the repo.

A skill is worth re-reading whenever the code it describes is restructured. Two that carry
more hardcoded detail than the rest, and so are worth checking first:

- **`database`** — a one-line-per-schema orientation map. Table detail is discovered live,
  so it can't drift, but the schema list and the purpose descriptions can. Re-sync after
  any schema is added, removed, or renamed: run `\dn` and reconcile against the map.
- **`public-keychain`** — points at specific model/source files _and_ a line range in
  another doc.

### `docs/support/*.md` — product overview docs

`product-overview.md`, `mac-app.md`, `ios-app.md`, `podcasts.md`. These are the
agent-facing source of truth for how the product works. Drift whenever features ship, are
renamed, or are removed. Review after any significant feature launch.

### Code-describing docs

Docs that describe how specific code works. They rot silently if the code they describe is
refactored. When touching any of the systems they describe, update the doc in the same PR.

- `docs/codegen.md` — swift/ts interop codegen
- `docs/templated-emails.md` — Postmark template system
- `docs/ios-block-rule-analysis.md` — iOS filter log analysis workflow
- `docs/ios-supervision.md` — iOS supervision process
- `swift/docs/pairql.md` — PairQL architecture
- `swift/docs/api-build.md` — Swift CI docker build + swift version bump procedure
- `swift/podcasts/docs/localization.md` — `LocalizedStringKey` / `lstr()` pattern and
  `.xcstrings` locations
- `swift/dev-emails/README.md` — local SolidStart tool for iterating on email HTML/CSS

### `web/site/docs/design.md` — marketing-site design system

Comprehensive reference for the marketing site's colors, typography, breakpoints, spacing,
buttons, cards, gradients, and animations. Referenced from `web/AGENTS.md` as the go-to
design doc. High drift surface because it hardcodes specific values (hex codes, class
names, px values). Periodic checks:

- Colors: verify hex codes in `## Color Palette` still match the actual values used —
  currently Tailwind defaults for violet-500, fuchsia-500, slate-900, etc. If a brand
  refresh changes any of them, the doc must be updated.
- Breakpoints, spacing, animations: verify against `web/shared/tailwind/src/preset.js` and
  `web/site/tailwind.config.js`.
- Fonts: verify family names match the tailwind `fontFamily` extends.
- Components (`FancyLink`, testimonial cards, etc.): after any refactor of shared or
  site-local components, re-check the `## Components` section.

## Hand-Mirrored Values

Hard-coded values that must be kept in sync across multiple files. Nothing enforces these
— changing one without the others creates silent drift.

### API prewarm package list — `Dockerfile.ci` ↔ `swift-ci.yml` ↔ `Package.swift`

The api's external dependencies are prebuilt into the CI image at `/prewarm` (so CI runs
reuse them instead of recompiling Vapor/NIO/etc). The api + its local path-dependency
closure is hand-listed in three places that must stay in sync:

- `swift/api/Dockerfile.ci` — one `COPY <pkg> ${PREWARM}/<pkg>` line per package (these
  are copied in and prebuilt during the image build).
- `.github/workflows/swift-ci.yml` — the `API_PREWARM_PKGS` env var (the `build-api` and
  `test-api` jobs rsync each one's freshly-checked-out sources into `/prewarm`).
- `swift/api/Package.swift` — the `.package(path:)` deps are the source of truth (find
  them with `grep '\.package(path:' swift/api/Package.swift`, then add their transitive
  `x-*`/ `pairql*` deps).

Drifts whenever the api adds/removes/renames a local path dependency. Failure modes: a
package missing from the `COPY` list breaks the **image build** (swift can't resolve the
path dep — loud, caught early); a package present in `COPY` but missing from
`API_PREWARM_PKGS` is **silent** — CI builds that dep from its stale image-baked sources
instead of the checked-out code. Keep all three lists identical.

### Prettier version — CI vs `web/package.json`

- `.github/workflows/swift-ci.yml` invokes `npx prettier@X.Y.Z` directly (twice, for the
  format-check steps that run against `web/` and `web/appviews/`).
- `web/package.json` pins `prettier` to the same version.
- Must match — if CI pins a newer version than `package.json`, format-check can fail on
  rules that weren't applied locally (or vice versa). Drifts whenever prettier is bumped
  in either place.

### `web/justfile` `check` recipe ↔ `web-ci.yml` build jobs

- `web/justfile`'s `check:` recipe lists per-app builds as dependencies (`build-site`,
  `build-storybook`, `build-admin`, etc.). Root `just check` and the final pre-PR
  verification command `just ci-local` both delegate here, so this recipe is the local
  mirror of the per-app build jobs in `.github/workflows/web-ci.yml`.
- Whenever a new per-app build job is added to `web-ci.yml`, the matching `build-*` recipe
  **must** be appended to `web/justfile:check` — otherwise the final pre-PR verification
  command (`just ci-local`) will silently skip it and PRs can pass locally while failing
  in CI.
- The `build-*` recipes should use `pnpm exec nx run <project>:build` (not
  `pnpm --filter <project> build`) so they benefit from nx caching during the
  frequently-run `just check` loop.

### SubscriptionPanel storybook fixtures ↔ `GetSubscriptionPanel_v2` resolver

- `web/storybook/stories/dash/Profile/SubscriptionPanel.stories.tsx` hand-mirrors every
  branch of the resolver at
  `swift/api/Sources/Api/PairQL/Dashboard/Pairs/GetSubscriptionPanel_v2.swift`. The grid
  is intended to cover all possible shapes of `GetSubscriptionPanel_v2.Output`.
- Drifts whenever the resolver gains, removes, or restructures a branch (new entitlement
  state, new action shape, change to primary/secondary composition, etc.). Nothing
  enforces the correspondence — drift silently degrades the design surface for the
  dashboard subscription panel.
- The story labels also embed real-world percentages (e.g. `(57.1%, n=433)`) sourced from
  a one-off prod-sync snapshot. These are a guide, not load-bearing — refresh from a
  current snapshot when the cohort distribution materially changes (e.g. after a pricing
  change or major migration).

### Podcast background task identifiers

- `swift/podcasts/lib-tca/Sources/Services/RegisterBgTasks.swift` defines the `BgTaskId`
  enum with the identifier strings (`com.netrivet.gertrude.am.refresh-feed`, etc.).
- `swift/podcasts/project.yml` lists the same strings under
  `BGTaskSchedulerPermittedIdentifiers`. Both files carry in-line "keep in sync" comments
  but nothing automated. Drifts whenever a background task is added, removed, or renamed.

### App Store ratings in marketing-site JSON-LD — `web/site/app/(marketing)/page.tsx`

- The `JSON_LD` graph's `SoftwareApplication` nodes for **Gertrude Blocker** and
  **Gertrude Podcasts** each carry a hand-typed `aggregateRating` (`ratingValue` +
  `ratingCount`). These are transcribed from what the App Store publicly displays, so they
  go stale continuously as ratings accrue — nothing refreshes them.
- Source of truth is the `appstore.rating_snapshots` table, refreshed on a schedule. Pull
  current values during a maintenance pass:

  ```sql
  SELECT DISTINCT ON (app) app, average_rating, total_count, created_at
  FROM appstore.rating_snapshots ORDER BY app, created_at DESC;
  ```

  Use `total_count` for `ratingCount` (all star ratings, not just written reviews) and
  `average_rating` rounded to one decimal for `ratingValue`, matching what the App Store
  itself shows so the numbers stay verifiable against the live listing.

- Failure mode is asymmetric. Understating drifts quietly and costs a little credibility.
  **Overstating** violates Google's review-snippet guideline that ratings "must be sourced
  directly from users" and risks a spammy-structured-markup manual action, which makes
  Google ignore the page's structured data until it's fixed and reconsidered.
- **Gertrude for Mac deliberately has no `aggregateRating`** — it has no App Store
  listing, so no honest rating source exists. Don't add one back.
- **There is no `SoftwareApplication` node for Gertrude Music yet.** Music is on the App
  Store but had 0 ratings as of 2026-08-18. Once it starts accruing real ratings, adding a
  node for it is worthwhile — `aggregateRating` (or `review`) is a _required_ property for
  the Software App rich result, so add the node only once there are genuine ratings to put
  in it, never with a placeholder.
- The standing fix that retires this chore: drive all of these from
  `appstore.rating_snapshots` at build time rather than hand-typing them, and surface the
  ratings visibly on the page (Google also requires marked-up review content be "readily
  available to users from the marked-up page", which the homepage currently isn't).
- Same block, same decay: the `offers.priceValidUntil` dates (currently `2026-12-31`) go
  stale on a fixed date — bump them while you're in here.

## Dev DB Scrubbing — `swift run Run scrub-db`

`swift/api/Sources/Api/Routes/ScrubDbCommand.swift` is the typed PII-scrubber that runs
server-side against a freshly-loaded prod copy before it's published as a scrubbed dump
for dev machines to pull. It's the source of truth for _what counts as PII for our dev
flow_ — the scrubbing decisions live in code, not in a SQL script.

**New fields and new tables are silent.** Whenever a model gains a column or a new model
is added, ask: does this hold a real secret (token/credential), real PII the team
shouldn't see in dev (free-text user content, contact info, customer-supplied
identifiers), or third-party-provider IDs we don't want bleeding into dev? If yes, add a
scrubber. The current explicitly-skipped set (kept in dev) includes parent emails, child
names, computer-user usernames, IP addresses, device UDIDs, unlock-request URLs/
hostnames, and free-text request comments — re-evaluate if the trust model changes.

## Annual: New macOS Release

Apple's cadence: the next macOS version name is announced at WWDC in early June, then
ships mid-to-late September.

**Start here.** `swift/gertie/Sources/Gertie/MacOSName.swift` is the shared source of
truth — add a `case` to the enum and a `switch` arm in `init(major:minor:)`, and point the
`default:` arm at the new case. Everything else keys off this enum, directly or by
mirroring its names.

**Then find the rest by grepping the previous release's name.** Any site that needs the
new version necessarily already names the old one, so the previous codename is a reliable
index of the work. Check both the camelCase enum spelling and the human display name:

```bash
grep -rniE "goldenGate|golden.?gate" . \
  --include="*.swift" --include="*.ts" --include="*.tsx" --include="*.js" \
  --include="*.just" --include="justfile" --include="*.md" --include="*.yml" \
  | grep -v node_modules
```

Don't trust a list of paths written a year earlier — the set moves as apps come and go.
Grep, then work through what you find. As of the macOS 27 pass, the hits clustered into
these kinds of work, which is what to expect:

- **Shared enum + its consumers** — the macapp and api read `MacOSName` directly.
- **Onboarding assets and flow** — by far the largest bucket. Per-OS screenshots and
  videos on the CDN, their hand-measured image coordinates, the step components that
  branch on OS, and the macapp's onboarding webview.
- **Internal display maps** — admin views that turn a major version number into a name.
- **Dev tooling** — a VM recipe for the new OS so it can actually be tested against.
- **Marketing site** — a supported-OS card plus its image asset.

**Assets carry forward; they aren't re-made up front.** The working pattern for anything
remote — onboarding images, GIFs, demo videos — is to duplicate the previous version's
assets under the new version's name, then replace individual ones later, only where the
new OS's UI actually changed enough to confuse someone following along. Most of it keeps
working untouched across a release.

That applies to the `/cu-*` `/du-*` `/su-*` user-management video redirects in
`web/site/_redirects` too: give the new version its own suffix immediately, pointed at the
previous version's YouTube URLs, and swap individual URLs if and when demos get
re-recorded (then bump the `# CREATE MACOS USER (current: X.Y.Z+)` marker). The point is
that the new version gets a complete, real slot from day one rather than falling through
to the old version's — a fall-through in the OS-to-suffix mapping is a bug, not a
placeholder, because it leaves nowhere to hang a new video later.
