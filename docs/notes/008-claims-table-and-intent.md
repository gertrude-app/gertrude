# 008 — `child.claims` table and `ClaimIntent`: first-class claim model

_Date: 2026-06-26._

## What we changed

Claim state — previously three columns on `child.ios_devices` (`claim_code`,
`claim_code_expires_at`, `claimed_at`) — now lives in a dedicated `child.claims` table.
Each row carries a `code`, `intent` (the `ClaimIntent` enum), `device_id` (NOT NULL FK to
`ios_devices`), optional `child_id` (populated on claim completion), `expires_at`, and
`claimedAt`. A partial unique index on `(device_id, intent) WHERE claimed_at IS NULL`
enforces at most one active unclaimed code per device/intent pair. A CHECK constraint
(`claimed_at IS NULL OR child_id IS NOT NULL`) enforces that a completed claim always
names a child.

`ClaimIntent` has four cases: `blockerSupervise`, `blockerConnect`, `music`, `podcasts`.

The deploy was a single migration: first it creates the table, then backfills from the
device columns using CASE logic, adds the partial unique index, and drops the three device
columns. No drain period was needed because the deploy is stop-the-world — old-server
readers of the dropped columns are fully down before the migration runs.

## Why

When blocker supervision was the only claim funnel, storing claim state on the device row
was fine. As music and AM were added, those same three columns got reused for all funnels.
The fundamental problem: a six-digit code had no intrinsic meaning. At lookup time, you
could not tell what app had minted it or reject it with a useful message if someone
entered a music code in the supervision funnel (or vice versa). The dashboard
`ClaimDevice` helpers now verify `claim.intent == intent` at the top and return a
user-readable "that code is for Gertrude Music, not Gertrude Blocker" error rather than a
generic "not found."

The free blocker connect funnel (the fourth, which motivated the whole refactor) would
have made the ambiguity unavoidable — `blockerSupervise` and `blockerConnect` codes exist
on the same device for the same app, so intent was no longer even theoretically
recoverable from context.

## Non-obvious decisions

**Backfill is automated, not hardcoded.** Master keeps minting codes until the deploy
lands, so the migration cannot use a snapshot. The CASE logic infers intent from existing
install rows (supervision row present → `blockerSupervise`; music-only install → `music`;
podcast-only → `podcasts`; multi-app unclaimed are ambiguous and fall back to
`blockerSupervise`). A pre-deploy SQL check confirms the ambiguous count is zero in prod
before deploying — a wrong-intent backfill for an ambiguous unclaimed code would just
cause that one user's claim attempt to be rejected, self-healing on next poll, but we
wanted confirmation the case didn't arise.

**`ensureActive` must delete expired unclaimed codes before minting.** Without this, when
an unclaimed code expires and the app re-polls, the insert hits the partial unique index
(the old expired row is still unclaimed) and throws a 500. Deleting stale unclaimed codes
before minting is the faithful equivalent of the old single-column overwrite semantics.
Live (non-expired) unclaimed codes are reused before reaching the delete path, so only
truly stale rows are removed.

**Supervision claims are reused after claiming; others are not.** `reusable(for:now:)`
lets supervision claims continue to be returned even after `claimedAt` is set —
`GetPendingSupervision` and related supervision-tool resolvers poll the same code through
the whole setup flow. Non-supervision funnels stop reusing once claimed (`blockerConnect`,
`music`, `podcasts`). The `renewIfPendingSupervision` path extends expiry for devices
still mid-supervision-setup.

**Concurrent mint safety.** `ensureActive` issues codes in a retry loop: if two concurrent
requests race to mint for the same `(device_id, intent)`, the second insert hits the
partial unique index, the catch block queries for the now-existing live claim, and returns
it. At most 20 attempts before alarming.
