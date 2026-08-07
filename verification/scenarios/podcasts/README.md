# Podcasts verification

**Naming bridge:** the podcasts app was *Gertrude AM* originally, and the wire-level cement
keeps that name — bundle id `com.netrivet.gertrude.am.dev`, PairQL surfaces `Am*` (e.g.
`GetAmClaimData`). Everything renameable has moved to **podcasts** (claim URL `gertrude.app/p/`,
dashboard route `/claim-podcasts-device`, with `/claim-am-device` as a legacy alias); all new
names use podcasts.

Initial target loop:

1. Reset/seed the task-local API database.
2. Run the API and dashboard on task-local ports.
3. Build and install the podcasts simulator app.
4. Drive onboarding until the app displays a podcasts claim code.
5. Claim that code through the dashboard for a seeded parent/child.
6. Let the app observe the claim.
7. Assert the backend recorded the claim through the typed PairQL oracle.
8. Set a PIN and reach the podcast home screen.
9. Add and play a deterministic fixture podcast.
10. Assert simulator-local SQLite state.
11. Pause playback after the assertion.

Current commands:

```bash
just verify-podcasts
just verify-podcasts app
just verify-podcasts flow
just verify-podcasts claim
just verify-podcasts pin
just verify-podcasts e2e
```

`e2e` resets the selected simulator app/keychain, resets the local API to known fixtures via
the maintained reset route, rebuilds/installs the app, drives onboarding to a claim code,
then drives the dashboard claim with Cypress (real browser against the live dashboard). Once
the app observes the claim, PIN setup is driven by Maestro.

**Server-state reset is the maintained reset route, not raw SQL.** `reset-api` hits
`/reset-$RESET_ROUTE_SUFFIX` (from `swift/api/.env`), which the API team keeps in lockstep
with the schema (`swift/api/Sources/Api/Routes/Reset/`). It is a *full* wipe + deterministic
reseed of staging fixtures — not a surgical clear of the simulator's row — so it also creates
the known test parents the claim uses. The harness has **no direct database access**: no
`psql`, no embedded SQL, and no direct model imports.

**The claiming parent is a fixture, not a DB lookup.** The claim is performed as **blanca** —
the seeded no-active-subscription parent (`AdminBlanca.swift`). Her dash token value equals
her parent id, so `admin_id == admin_token == BE400000-0000-0000-0000-000000000000`
(overridable via `DASHBOARD_ADMIN_ID` / `DASHBOARD_PARENT_TOKEN`). No `parent.dash_tokens`
query, no "first token" heuristic. Because blanca has no pre-seeded child, the claim form
creates `Verification Child` unless `DASHBOARD_CLAIM_CHILD_NAME` overrides it. Blanca exists
only *after* a reset, so `claim` expects a prior `reset-api` (the `e2e` ordering guarantees
this; `reset-sim` is the separate simulator-side teardown — uninstall + keychain reset — and
doesn't touch the API).

The dashboard tier is black-box via a real browser, scripted with **Cypress** — the web
analog to Maestro for the app tier. The deterministic specs live in `dashboard/` next to the
Maestro `flows/`, and run against the live dashboard (`http://localhost:$DASH_PORT`) and the
real local API, not PairQL curl calls:

- `dashboard/e2e/claim.cy.js` — drives the claim form (assign device to a child) and submits.

These specs intentionally assert **behavior through phases, not copy**. The dashboard's own
unit/cypress suites own exact-copy and component coverage; this harness only proves the
cross-tier claim moves through its phases and takes the critical actions, with maximum
resistance to copy/layout drift. Concretely:

- The backbone is **route transitions** (`/claim-podcasts-device/:code/claim` → `/done`). The
  redirect to `/done` only fires when `GetAmClaimData` finds a persisted claim in the real
  backend, so the URL change *is* the cross-tier assertion — and it has no copy coupling.
- The claim action targets **structural hooks** — `[data-test=child-name-input]` and
  `button[type=submit]` — not button/label copy. When the account already has children, the
  pre-selected default child is submitted as-is (no new child created); only an empty account
  requires typing a name (`CYPRESS_CHILD_NAME`, default `Verification Child`).
- The only text assertion is a loose, case-insensitive `connected` word-fragment as a soft
  "reached the success screen" marker.

The `run` script seeds blanca's fixture `admin_id` + token into `localStorage` (real-login) and
shells `pnpm cypress run --project dashboard` with the claim code / child name as `CYPRESS_*`
env. Cypress is invoked from `web/` (where it is a dev dependency); the specs are plain JS to
stay self-contained outside the `web` pnpm workspace. `--headed` (e.g.
`just verify-podcasts claim --headed`) runs the specs in a visible browser; the default
is headless.

The simulator app talks to the task-local API via `http://127.0.0.1:$API_PORT`, with
`API_PORT` and `DASH_PORT` loaded from `.gtask-ports` when present. The dashboard Cypress
config and PairQL oracle expect the runner to pass those values explicitly. The simulator
loop does not use a public tunnel.

Shared environment, simulator selection, reset-route handling, and status helpers live in
`verification/lib/common.sh`. Podcasts-specific constants live in `config.sh`.
