# 009 — Gertie shared Swift module structure

_Date: 2026-06-19 (decided 2026-06-17, shipped in PR #751 `blocker-crosspromo`)._

> **Read this before creating a new SPM package or target, or whenever you're unsure where
> a shared Swift type or feature belongs.** It gives the semantic purpose of each shared
> module and the rule for choosing a new _target_ vs a new _package_.

## The module map

Two packages hold code shared across the Gertrude apps. Everything else (`api`, `macapp`,
`iosapp`, `podcasts`, `music`, the `pairql-*` route packages, the `x-*` utilities)
consumes them.

### `swift/gertie` — shared DATA / types (dependency-light, server-safe, TCA-free)

One package, several independent **targets**. Platform floor `macOS .v10_15 / iOS .v17`,
swift-tools 6.0. This is the monorepo's cross-cutting container for shared _types_; add
new targets freely.

- **`Gertie`** — the core, cross-platform parental-controls domain: `BlockRule`,
  `RuleKeychain` / `RuleSchedule`, `FilterSuspension`, `SecurityEvent`, `NetworkDecision`,
  `AppScope` / `AppDescriptor`, `UserFilterState`, and friends. The shared filtering /
  monitoring vocabulary. Consumed by `api`, `macapp`, and the `iosapp` blocker.
- **`GertieBlocker`** — the **blocker app's** domain specifically: `BlockGroup`,
  `WebContentFilterPolicy`, and blocker-only extensions. Re-exports `Gertie` (see
  `Exports.swift` below), so a `GertieBlocker` consumer sees the core types too. Consumed
  by `api` (~30 files) and the `iosapp` blocker. (This is the renamed old `GertieIOS` —
  see naming below.)
- **`GertieApp`** — **cross-app wire types** shared by _all_ the apps plus the server:
  every iOS app (blocker, podcasts / AM, music), the Mac app, and the `api`. First tenant
  is the cross-promotion campaign model (`CrossPromoCampaign` and its CTA / action / style
  / image family, plus the lossy forward-compat decoder). **Zero dependencies, plain
  `Codable`** — keep it that way. This is where a type shared _across the app family_
  goes.

### `swift/gertie-tca-features` — shared BEHAVIOR (client TCA apps only)

Product `GertieTcaFeatures`. Platform floor `macOS .v15 / iOS .v17`, swift-tools 6.1;
depends on `GertieApp` + The Composable Architecture + swift-dependencies. Holds shared
_reducers_ and TCA-adjacent helpers: the `CrossPromoFeature` reducer, the `SharePresenter`
(UIKit share sheet), and campaign-behavior helpers. Consumed by the client TCA apps only
(`iosapp/lib-ios`, `podcasts/lib-tca`, and the future music app) — **never by the `api`.**

Mental model: **`gertie` = shared data; `gertie-tca-features` = shared behavior.**

## The rule: new _target_ vs new _package_

The load-bearing fact is a subtlety of SwiftPM:

> SwiftPM compiles **per target**, but resolves dependencies and platform floors **per
> package.** A consumer that imports just one product of a package still inherits that
> whole package's dependency graph and minimum platform during resolution.

So:

- **Default: add a new _target_ under `swift/gertie`.** Because compilation is per-target,
  a music app can `import GertieApp` without compiling `GertieBlocker`'s filtering domain.
  New shared types are cheap this way — no new package, and no new dependency imposed on
  anyone.
- **Reach for a new _package_ only when a chunk needs a heavy / opinionated dependency (or
  a higher platform floor) you don't want imposed on every `gertie` consumer — above all
  the API server.** TCA is the canonical trip-wire: putting it in `gertie` would force
  `api` (Linux, no TCA, low platform floor) and `macapp` to resolve a client-UI framework
  and risk version-pin conflicts. That is exactly why `gertie-tca-features` is its own
  package.

Keep `gertie` dependency-light, server-safe (`macOS .v10_15`), and TCA-free. Keep the
`api` off `gertie-tca-features`.

## Why the shared wire types are a _target in `gertie`_, not a standalone package

This was the live decision, and it was made twice:

1. The work started with a planned standalone `swift/crosspromo` package (matching the
   `swift/x-*` convention). It was **folded into `gertie` as the `GertieApp` target** once
   the "one family-wide bucket to pull from" principle was affirmed — a music app
   depending on `gertie` is fine, and per-target compilation keeps the filtering domain
   out of its build.
2. A dependency conflict then tempted a re-split: `podcasts/lib-tca` (Gertrude AM)
   hard-requires `swift-tagged >= 0.10.0` (via the `StructuredQueriesTagged` trait), while
   the monorepo's `jaredh159/swift-tagged` fork was pinned at `0.8.2`. Since consuming
   _any_ `gertie` product drags gertie's fork dependency into AM's solve, one fix was to
   extract `GertieApp` into its own zero-dep `swift/gertie-app` package. **That was
   considered and rejected:** instead the fork was bumped to `0.10.1` (mainline `0.10.0` +
   the two fork patches), keeping `GertieApp` a target inside `gertie`. **We preserved the
   layout and fixed the dependency.** (The fork exists for its lowercase-UUID encoding
   patch; do not migrate the repo to mainline swift-tagged.)

## Naming

- **`GertieIOS` → `GertieBlocker`.** The old name read as "iOS-platform code" or "shared
  iOS-apps code," but the target is actually the _blocker app's_ domain (and the server
  imports it heavily). The rename tells the truth and freed the namespace for a genuinely
  shared module.
- **`GertieApp` is scoped to include the Mac app and the server** — hence "App," not
  "IOS." Its wire types are family-wide (all iOS apps + Mac + `api`). `GertieIOS` would
  have excluded the Mac app and forced a rename the day it adopts a cross-app feature.
- **Lean into `podcast` / `blocker` / `music` at call sites**, not "iOS app." There are
  now three iOS apps; "the iOS app" is no longer a synonym for the blocker. (E.g. the api
  resolvers are `PodcastCrossPromos` / `BlockerCrossPromos`, not one ambiguous
  `CrossPromos`.)

## Conventions that fell out of this

- **Re-export moved types with `@_exported import` in an `Exports.swift`.** When shared
  types move into `GertieApp`, a route module can re-export them so existing
  `import PodcastRoute` (etc.) consumers keep seeing them with no import churn.
  Established idiom: `GertieBlocker` re-exports `Gertie`; `MacAppRoute` re-exports
  `PairQL`.
- **Views are never shared.** iOS uses SwiftUI; the Mac app uses a webview + React. Share
  reducers and types, not views.
- **Share the wire types + reducer + server catalog; duplicate the rest on purpose.** Each
  app keeps its own view, its own persistence, its own PairQL pair, its own root-reducer
  wiring, and its own placement / string constants. A shared abstraction over those was
  judged net-negative.

## What this means for new code

- A **type shared by two or more apps (or an app and the server)** → `GertieApp` (plain
  `Codable`, no heavy deps). A distinct shared _domain_ can be its own new target under
  `gertie`.
- A **blocker-specific type the server also needs** → `GertieBlocker`. Core cross-platform
  parental-controls domain → `Gertie`.
- **Shared TCA behavior** (a reducer / feature for the client apps) →
  `gertie-tca-features` (`GertieTcaFeatures`). Never make the `api` depend on it.
- **Only mint a new package** when a shared chunk needs a dependency or platform floor you
  don't want imposed on all of `gertie`'s consumers (especially the server). Otherwise a
  new **target** under `gertie` is the answer. Don't add TCA or other heavy deps to
  `gertie`.
- Adding a shared SPM package requires nx registration (a `project.json`, mirroring an
  existing package); run `pnpm exec nx reset` from `swift/` after adding.
