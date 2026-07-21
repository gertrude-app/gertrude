# Tier 2: Release-branch gating for dashboard deploys

_Status: exploratory. Files staged in this branch but not yet committed beyond
the WIP commit. Nothing here is live._

## The thing in one sentence

Cloudflare Pages stops tracking `master` and starts tracking a `release` branch.
A small GH Action decides on every dashboard-affecting master push whether to
fast-forward `release` automatically (no contract change → safe) or hold it
(contract changed → wait for API deploy). The API prod-deploy ritual gains one
new command — `bash scripts/promote-dashboard.sh` — that verifies the prod API
is on the matching contract and then performs the held promote.

Result: dashboard-only changes ship instantly, contract-changing PRs are
physically incapable of going live ahead of the API, and you don't have to
remember anything.

## How the pieces line up

```
PR merged to master
        │
        ▼
┌──────────────────────────┐
│ .github/workflows/       │   reads web/shared/pairql/src/dashboard/contract.ts
│   dash-promote.yml       │   curls https://api.gertrude.app/dashboard-pairql-contract-hash
└──────────────────────────┘
        │
   hashes equal? ─── yes ──▶ git push origin master:release ──▶ Cloudflare Pages deploys
        │
        no
        │
        ▼
   Slack: "🟡 Dashboard <sha> HELD — run scripts/promote-dashboard.sh after API deploy"
                                                                  │
                                                                  ▼
                                              (existing) "Gertrude api DEPLOY READY" → human SSHes,
                                              swaps current symlink, restarts pm2 production
                                                                  │
                                                                  ▼
                                              human runs: bash scripts/promote-dashboard.sh
                                                  • polls prod API for matching hash
                                                  • git push origin master:release
                                                                  │
                                                                  ▼
                                                       Cloudflare Pages deploys
```

## What's in this branch already

### Code (staged, uncommitted on top of WIP commit)

| File | Purpose |
|---|---|
| `swift/api/Sources/Api/Configure/router.swift` + `Routes/DashboardTsCodegen.swift` | New `GET /dashboard-pairql-contract-hash` route — returns the cached `currentContractHash` as 64-char plain text, O(1). |
| `.github/workflows/dash-promote.yml` | The auto-promote/hold decision on master push. |
| `scripts/promote-dashboard.sh` | One-shot, idempotent, prod-hash-verifying promote. Called by you after API prod cutover. |
| `tier-2-rollout-plan.md` (this file) | The plan you're reading. |

### Behavior notes

- The workflow's `paths:` filter matches `web-ci.yml`'s `dashboard` filter
  exactly (`web/dash/**`, `web/shared/**`, `swift/api/Sources/Api/PairQL/Dashboard/**`).
  Spurious runs are no-ops because the promote step is idempotent — pushing
  master's SHA to release when release is already there does nothing.
- The **expected** hash (the one baked into the new dashboard build) is read
  from `contract.ts` with `grep -oE '[0-9a-f]{64}'` — the generated file has
  exactly one such string.
- The **prod** hash is fetched from the dedicated
  `/dashboard-pairql-contract-hash` route as plain text — no JSON, no jq,
  validated by regex `^[0-9a-f]{64}$`.
- The script polls prod for up to 180s (configurable via `TIMEOUT_SECONDS`),
  5s interval. Tunable from the env.
- The hash comparison source of truth is `contract.ts` (what's baked into the
  JS bundle), not a freshly-built API binary in CI. That's the correct compare:
  it asks "will the browser, when loaded, see a matching server header?" If
  someone forgot to run codegen, `verify-pairql-codegen` in `swift-ci.yml`
  already blocks the PR — so on master HEAD `contract.ts` is always fresh.

## Out-of-band ("click-ops") steps, in order

These are the things you cannot do from code. Listed in safe rollout order;
each is reversible without touching the others.

### 0. Prerequisite — staleness-detector in prod

The workflow and the script both require the dedicated
`/dashboard-pairql-contract-hash` route (registered in `router.swift`,
implemented as `DashboardTsCodegenRoute.hashHandler`). That route returns the
cached `currentContractHash` as a 64-char hex string with
`Content-Type: text/plain` — O(1) per request, no jq/JSON in the consumers.
It ships in the staleness-detector PR. Until that PR is in prod, both the
workflow and the script will fail with a clean error.

After it's live, sanity-check from your laptop:

```sh
curl -fsSL https://api.gertrude.app/dashboard-pairql-contract-hash
# should print a 64-hex-char string and nothing else
```

### 1. Create the `release` branch on GitHub

From master, after the staleness-detector PR is merged and prod is on it:

```sh
git fetch origin master
git push origin origin/master:refs/heads/release
```

The branch now exists, pointing at the same commit Cloudflare Pages is
currently building from. No deploy fires (CF Pages still tracks master).

### 2. Add branch protection to `release`

GitHub → Settings → Branches → Add rule for `release`:

- ✅ Require a pull request before merging — **off** (release is push-only by automation; PRs to it are not the model).
- ✅ Restrict who can push to matching branches — **on**:
  - Allow `github-actions[bot]` (the actor that runs the workflow).
  - Optionally allow your own user, for emergency manual push.
- ✅ Do not allow bypassing the above settings — **off** (you need bypass for the bot push).
- ❌ Status checks — **off** for `release` (status checks already ran on master before merge; release is just a promotion pointer, not a code-review surface).
- ❌ Allow force-pushes — **off**.
- ❌ Allow deletions — **off**.

If your org's branch-protection model doesn't expose `github-actions[bot]` as
a selectable actor, fall back to a PAT: create a fine-grained PAT with
"Contents: write" on this repo, save as `RELEASE_PROMOTE_TOKEN`, and add a
small step to the workflow to swap the remote URL before `git push`. Skeleton:

```yaml
- name: promote — fast-forward release branch
  if: steps.decide.outputs.action == 'promote'
  env:
    GH_TOKEN: ${{ secrets.RELEASE_PROMOTE_TOKEN }}
  run: |
    git config user.name  "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git push origin "${GITHUB_SHA}:refs/heads/release"
```

### 3. Land the workflow + script (this PR)

Merge `dash-promote.yml`, `promote-dashboard.sh`, and this plan to master.

Now things start happening:
- Every dashboard-affecting master push fires `dash-promote.yml`.
- It posts to Slack `#deploys` (channel `C08GLK13HAB`, same channel as the
  existing API "DEPLOY READY" message).
- On a no-contract-change push, it fast-forwards `release` automatically.
- Cloudflare Pages still tracks **master** at this point, so the release
  branch updating doesn't deploy anything. This is intentional — it lets you
  watch the workflow do its thing safely for a few merges before flipping CF.

### 4. Flip Cloudflare Pages production_branch

Cloudflare dashboard → Workers & Pages → (your dash project) → Settings → Builds & deployments → Production branch.

Change from `master` to `release`. Save.

The next time the workflow fast-forwards `release`, CF Pages deploys. The next
time it leaves `release` alone, CF Pages does nothing. Tier 2 is live.

> If your CF Pages project also has "preview deployments" enabled on all
> branches, you may want to disable preview deploys on `master` specifically
> so you don't double-build on every merge. Optional.

### 5. Modify your API prod-deploy ritual

Wherever your "API DEPLOY READY → I SSH and swap pm2" runbook lives (mental,
README, Notion, whatever), append one line:

> After verifying production is healthy on the new binary, on your laptop:
> `bash scripts/promote-dashboard.sh`

That's the dummy-proof bit. The script:
- exits 0 immediately if release is already at master (e.g., the API deploy
  was for a backend-only change that the workflow already promoted),
- otherwise polls prod for the matching contract hash and only then pushes.

If you forget, the held dashboard sits on the previous build until the next
master push that has a matching hash, or until you remember. Worst case is
delayed dashboard, never broken dashboard.

## Acceptance test (after step 4)

Two scenarios to verify, ideally on the next merge of each shape:

1. **Dashboard-only change**: e.g. a CSS tweak. Expected: workflow posts
   "✅ promoted", CF Pages deploys within minutes, no API involvement.
2. **Contract-changing change**: any PR that modifies a dashboard PairQL
   input/output shape. Expected: workflow posts "🟡 HELD", CF Pages does NOT
   deploy, dashboard stays on previous version. After API prod cutover, running
   `bash scripts/promote-dashboard.sh` polls briefly, pushes release, CF Pages
   deploys.

## Edge cases and known limitations

- **Multiple master commits between API deploys.** Say merge A is a held
  contract change; B is a CSS-only change. On B's push, the workflow checks
  contract hash — it still differs from prod (because A's change is in there)
  — so B also holds. The release branch stays at the pre-A SHA until you run
  the promote script, which advances release to the latest master (A+B
  together). This is correct: B shouldn't ship the new contract either.
- **Rolling deploys / multi-instance API.** The script polls a single endpoint;
  if the API runs behind a load balancer with multiple instances mid-rollout,
  it may briefly see the new hash from one instance and the old from another.
  Current behavior: first sighting of the matching hash promotes. Acceptable
  per the original task brief ("not race-proof"); the in-tab staleness
  detector handles the residual seconds-window for already-open tabs.
- **`release` and `master` diverge if anyone hand-pushes to release.** Branch
  protection prevents this; if you ever need to bypass for an emergency
  rollback, you can force-push release to an older master SHA — CF Pages will
  redeploy the older bundle.
- **Workflow can't run if `contract.ts` doesn't exist yet.** True only during
  the bootstrap window before the staleness-detector PR is merged. Caught with
  a clear error in step `read new dashboard contract hash`.
- **No protection against a non-contract-affecting backend change that ALSO
  needs lockstep.** E.g., the API renames an env var the dashboard reads at
  runtime via some other channel. Out of scope: the contract hash only knows
  about PairQL shapes. If you ever build other dashboard↔API coupling, you'd
  need a separate signal.

## Rollback

Each step undoes cleanly:

- **Step 5 (runbook line):** just stop running the script. No state.
- **Step 4 (CF Pages production_branch):** flip back to `master`. Next master
  push deploys immediately like before.
- **Step 3 (workflow + script):** delete the files in a PR, or just disable
  the workflow in the GitHub UI. Master pushes go back to firing nothing
  extra.
- **Step 2 (branch protection):** remove the rule. Nothing else cares.
- **Step 1 (release branch):** `git push origin --delete release`.

Total rollback time: maybe ten minutes if you're unhurried.

## What this does NOT do

- It does not automate the API prod cutover itself. The human SSH-pm2 step
  remains. Automating that is orthogonal (Tier 4 in the brainstorm) and can
  layer on later without touching any of this.
- It does not pre-flight contract-breaking PRs at PR-open time. Tier 0 (a CI
  job that comments on PRs) is also orthogonal and cheap; would be a separate
  10-line job posting a `pairql-breaking` label.
- It does not handle dashboard rollback. If a dashboard deploy goes bad you
  can force-push `release` back to an earlier SHA from your laptop with the
  branch-protection bypass; CF Pages redeploys the older bundle. Worth
  documenting in the runbook but no code needed.

## Open questions for you

1. **Slack channel.** Workflow currently posts to `C08GLK13HAB` (same as the
   API DEPLOY READY messages). Right channel? Or a quieter one?
2. **PAT vs `github-actions[bot]` bypass.** Which fits the org's existing
   pattern better? (The other workflows in `.github/workflows/` use
   `${{ secrets.SLACK_API_TOKEN }}` and SSH keys, not a custom GitHub PAT — so
   if you don't already have one, the bypass path is cleaner.)
3. **Naming.** Is `release` the branch name you want? `prod`, `deploy`,
   `cf-prod` are all viable. Easy to rename now, irritating later.
4. **Timeout in `promote-dashboard.sh`.** 180s default. If your API restart +
   warmup takes longer in worst case, bump it.
