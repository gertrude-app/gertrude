# Agent-driven verification

This directory is for repeatable, multi-surface verification scenarios that can be driven
by agents and rerun by humans.

The shape is intentionally scenario-oriented:

- `scenarios/podcasts` proves the first iOS app + API + dashboard loop.
- `scenarios/blocker` proves the first simulator-drivable blocker onboarding slice.
- `scenarios/music` explores the first Gertrude Music simulator + API loop.
- Future scenarios can sit beside it for the blocker app, music app, macOS app, or mixed
  dashboard/API flows.

The harness needs **two endpoints** — the local API and the dashboard. It does not assume
where those come from; the surrounding environment fulfills the contract, resolved in this
order (first match wins):

1. **A ports file**, if present — sourced and authoritative. Defaults to `.gtask-ports` at the
   repo root (the per-task port allocation used by the task/worktree workflow); point it
   elsewhere with `VERIFY_PORTS_FILE=/path/to/file`. Being authoritative keeps a task-local
   allocation from being silently overridden by a stale ambient env var.
2. **Explicit env vars** (when no ports file) — `API_ENDPOINT` / `DASH_URL` (full URLs), or
   `API_PORT` / `DASH_PORT` (loopback ports). Set these however your workflow exposes them.
3. **Repo defaults** — `API_PORT=8080`, `DASH_PORT=8081`, matching a vanilla `just watch-api`
   and `just dash`, so a plain checkout with the standard local stack running needs no config.

Shared shell helpers live in `lib/common.sh`. Scenario-specific constants live next to each
scenario in `config.sh`; keep new app-surface values there instead of scattering them through
Maestro flows, Cypress configs, or PairQL oracles.

## Guiding principles

These loops exist to give a **binary pre-release signal we trust enough to ship on** — the
cross-surface integration (app ↔ API ↔ dashboard) that no unit test can see and that used to
be verified by hand. Everything below serves that; when in doubt, protect the signal.

- **Grow seam-driven, not scenario-count-driven.** A new e2e scenario earns its place by
  covering a *new cross-surface seam* (a claim handshake, subscription-state propagation, a
  dashboard-action-observed-by-app loop) — not by re-walking mostly-covered wiring with a
  thin sliver of new behavior. Code-path breadth belongs in the cheap deterministic tiers
  (TCA reducer tests, API integration tests, typed PairQL oracles); the simulator layer stays
  a thin slice per seam. The UI flow is the most expensive place to buy coverage — spend there
  only for what only it can prove.
- **Growth is budget-gated, and the budget is earned.** Suite reliability compounds
  multiplicatively: at a 98% per-flow pass rate on healthy code, ten flows are green ~82% of
  runs, thirty ~55% — at which point "the suite is green" carries no information. Two numbers
  gate growth: the **green-run rate** on healthy code, and the **wall-clock** of the full
  pre-release gate. Add scenarios only while both stay boring.
- **A flow that flakes twice without finding a product bug gets fixed or demoted** before
  anything new lands. Noise erodes the signal even when triage is cheap.
- **The oracle is typed; the behavior under test is real.** Actions go through the real UI
  (Maestro, Cypress); assertions go through the generated PairQL contract so drift breaks at
  `tsc` time, not as a confusing runtime miss. Don't assert through raw SQL or scraped UI when
  a typed contract can carry the assertion.
- **Distinguish journey assertions from change-detectors.** "The flow completes and yields a
  claim code" is the release gate; "the screens appear in exactly this order" is a deliberate
  change-detector that breaks on every copy tweak. Both are legitimate — but choose per flow,
  on purpose.
- **Suspect the environment first, and keep teaching the harness to own it.** The recorded
  failure history here is almost entirely stale infrastructure, not product bugs (see
  Gotchas below). When a gotcha recurs, promote it from documentation to a hard preflight
  check — the harness should refuse to run against stale servers or binaries rather than
  rely on a human remembering.
- **The suite only has value if it's actually run.** These loops are a pre-App-Store-release
  ritual, driven by an agent, with a red run blocking until explained. Un-run smoke tests rot
  silently and fail you the one day you need them.

## Naming & layout conventions

- **Product names over codenames.** Scenarios are named for the products as the root
  `AGENTS.md` names them (`podcasts`, `blocker`, `music`) — never internal codenames (`am`,
  `fm`) or repo dir names (`iosapp`). Immovable codenames (PairQL pairs like `GetAmClaimData`,
  bundle ids, dashboard routes) are bridged once at the top of the scenario README; everything
  harness-side speaks the product name.
- **One journey per scenario dir today; nest when a second arrives.** Each `scenarios/<app>/`
  currently holds a single claim-centric journey. When an app gains a second journey, restructure
  to `scenarios/<app>/<journey>/` with the app-scoped `config.sh` shared at the app level —
  don't fork a sibling top-level dir.
- **Flow files are named for the journey segment they actually cover, start to end**
  (`onboarding-to-claim-code.yaml`, `pin-and-first-show.yaml`) — not the feature they brush
  against.
- **Shared command vocabulary, identical meaning in every scenario**: `preflight` (check
  prerequisites), `app` (build + install + launch), `flow` (the Maestro-only simulator slice),
  `claim` (cross-surface dashboard claim + app observation), `reset-api` (reseed API fixtures;
  installed app untouched), `reset-sim` (uninstall app + reset keychain; API untouched), `e2e`
  (compose all of the above). Scenario-specific phases get their own verb (`pin`, `approve`,
  `dashboard`); the shared verbs must never widen or narrow per scenario.
- **Accessibility ids**: screens get `onboarding-screen-<semantic-name>` (name the meaning,
  not the copy); shared/generic buttons get `btn-<role>` (`btn-primary`, `btn-secondary`).
  One convention across all apps.

Current entry points:

```bash
just verify-podcasts
just verify-blocker
just verify-music
just verify-podcasts app
just verify-podcasts e2e
```

## Setup (first run on a new machine)

Run `just verify-<scenario> preflight` first — it checks every prerequisite below and prints
`ok` / `warn` / `missing` for each, so you don't have to discover them one failure at a time.

- **Tools** (macOS only — these loops drive the iOS Simulator): `just`, `xcrun` (Xcode),
  `maestro`, `xcodegen`, `pnpm`, and `sqlite3`. Cypress is installed by `pnpm --dir web install`.
- **Local stack running**: `just watch-api` and `just dash`, plus a booted Simulator. The app
  under test must be built + installed — `just verify-<scenario> e2e` does the reset → build →
  install → drive chain end-to-end; `flow` assumes the app is already installed.
- **Simulator on iOS 26+.** The flows rely on native `.searchable`, which hangs on older
  simulators. The harness errors if the selected sim is < iOS 26; set `VERIFY_ALLOW_OLD_SIM=1`
  to override (e.g. to exercise the pre-26 fallback path).
- **Env files** (both gitignored — obtain via the normal dev-secrets bootstrap):
  - `swift/api/.env` needs `RESET_ROUTE_SUFFIX` (the maintained reset route that seeds fixtures;
    without it the claim parent never exists). The **music** scenario also needs
    `MUSICKIT_KEY_ID`, `MUSICKIT_TEAM_ID`, `MUSICKIT_PRIVATE_KEY` (it hits the live Apple Music
    catalog).
  - `web/dash/app/.env.local` needs `VITE_API_ENDPOINT` pointing at the same local API, so the
    dashboard the Cypress claim drives talks to the right backend.
- **Ports** are resolved by the contract described above — no action needed if you run the
  standard stack or export your own `API_PORT`/`DASH_PORT`.

## Gotchas / known pitfalls

When a flow fails in a way that looks like an app or product bug, suspect the **environment**
first — most of the time sunk here has been stale infrastructure, not real regressions:

- **Stale dashboard dev server.** `just dash` (Vite) can run for days and silently serve stale
  code if its file-watcher dies — a newly added dashboard route then matches nothing and renders
  a blank page, so a Cypress claim fails at `cy.get('form')` with *no error*. Check what's
  actually served, not just what's on disk: `curl -s localhost:$DASH_PORT/src/App.tsx | grep
  <route>`. Fix by restarting `just dash` (kill this task's own vite only; leave sibling tasks'
  servers alone).
- **Stale installed iOS app.** The simulator keeps the last-built binary. After app or API
  changes (e.g. a PairQL contract change) the old binary can crash mid-flow — e.g. blocker code
  generation drops to the home screen (or whatever app was last foregrounded), which *looks* like
  a UI regression. Rebuild+reinstall with `just verify-<scenario> app` before trusting a flow
  failure.
- **Assert stable screens, not transient ones.** Reducers auto-advance the instant backend state
  changes: the blocker app's 5s poll sees the claim and jumps past the transient
  `connect-account-success` view straight to `connectSuccess`, so asserting the transient id never
  lands. Assert the terminal stable screen with `extendedWaitUntil` + a timeout covering the poll
  cadence.
- **Loopback, not ngrok.** The app (`just swift iosconfig` → `127.0.0.1:$API_PORT`) and dashboard
  (`VITE_API_ENDPOINT` in `web/dash/app/.env.local`) both hit the local API directly; the sim
  reaches the host with no tunnel. `NGROK_SUBDOMAIN` in `.gtask-ports` only feeds the unused
  `ios-tunnel` recipe — a flow never needs it.
- **Background-run exit codes.** A trailing `echo` after a `just`/`maestro` command makes the
  harness report exit 0 regardless; capture the real code (`RC=$?`) into the log and check that.
- **Simulator SpringBoard crashes mid-run (Apple bug, not ours).** A step fails on state the
  app demonstrably reached, and a macOS crash-reporter dialog appears; the respring kills the
  foregrounded app, so later hierarchy reads see the home screen. The `.ips` in
  `~/Library/Logs/DiagnosticReports/` shows SpringBoard segfaulting in
  `XCTAutomationSupport -[XCTAutomationSession initWithAccessibilityFramework:...]` — the
  accessibility bridge Maestro attaches through. The trigger is automation-session
  attach/detach churn (observed on both a 23h-old and a 45-min-old simulator, each time on a
  fresh attach right after a prior session detached), so prefer one Maestro flow with
  `extendedWaitUntil` over shell loops that poll `maestro hierarchy`. Recovery: reboot the sim
  (`xcrun simctl shutdown <udid> && xcrun simctl boot <udid>`) and rerun from `flow` — the
  podcasts app doesn't persist onboarding progress, so a respring means redriving onboarding.
  Environment flake, never an app regression; the podcasts claim step now detects a fresh
  SpringBoard `.ips` and says so in its failure output.
