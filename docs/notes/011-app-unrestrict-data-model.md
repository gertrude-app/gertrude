# 011 — Giving "app has unrestricted internet" a real home

_Date: 2026-05-19. Mac app cutoff: **none** — the wire contract is unchanged (this is the
central enabling fact, see below)._

## The decision in one line

Introduce a first-class, child-scoped `UnrestrictedMacApp` model — a near-mirror of the
existing `BlockedMacApp` — as the home for "this app has unrestricted internet for this
child", migrate the legacy keychain-resident app keys into it, and synthesize the legacy
keychain shape back at the Mac-app wire boundary so nothing downstream changes.

## The tension

"This app has unrestricted internet for this child" is not something the data model
stores. It is an **emergent projection** over three legacy entities:

- `Key` with scope `.skeleton(scope: .single(.bundleId | .identifiedAppSlug))` ("this app
  bypasses the filter"),
- the `Keychain` it happens to sit in (a sharing/reuse construct, possibly `isPublic`),
- and the `ChildKeychain` join binding that keychain to a child.

Consequences of having no home:

- **Wrong grain.** The concept is per-child, but the model's grain is the keychain.
- **Coarse scheduling.** A schedule can only be attached at the `ChildKeychain`
  (child↔keychain) grain — never per app. Per-app scheduling of app-unrestrict is
  effectively impossible for parents today.
- **Smuggling.** App-unrestrict keys are intermixed with website keys inside keychains,
  and the keychain abstraction (sharing, public bundles, schedule carrier, wire container)
  leaks into a concept that wants none of it.
- **An asymmetry that is itself the tell.** The _blocked_ half of this exact feature
  already lives in the world we want: `BlockedMacApp` is child-scoped, carries app
  identity and an optional per-app `RuleSchedule`, and touches no keychain. Only the
  _unrestricted_ half is contorted. We are not inventing a paradigm — we are restoring
  symmetry to one that already ships.

## Alternatives considered

- **(A) Read-through lens, no model change.** Resolve skeleton single-app keys across a
  child's keychains into a clean list; write new grants into a default keychain. Zero
  migration. Rejected as the _end state_: it papers over the read projection but leaves
  the model debt in place and relocates the hard part to the remove-from-shared-keychain
  path. Retained only as a discarded transitional shim (see "single PR" below — we don't
  even ship it).
- **(B) Hidden per-child app-keys-only keychain.** One concealed keychain per child for
  all app keys. Rejected: gives _one_ schedule for _all_ app keys — fails the per-app
  schedule requirement outright.
- **(1) Synthetic 1:1 keychain-per-app to preserve the keychain illusion.** Auto-create a
  hidden `Keychain` + `ChildKeychain` per app so a schedule can ride the keychain.
  Rejected: it is `Keychain` + `ChildKeychain` per app per child, leaks into every
  keychain-enumerating surface forever, _still_ requires a migration of legacy data, and
  entrenches the very abstraction we want to move away from. Deceptively the most
  expensive option, not the cheapest.
- **(C, chosen) First-class child-scoped `UnrestrictedMacApp` + synthesize keychains at
  the wire.** Mirrors `BlockedMacApp`. Resolves the debt at the source; the migration is
  bounded; the Mac app never notices.

## What anchored the decision: the wire fact + the production-shaped audit

Two findings collapsed the perceived cost and risk of (C).

**The Mac app does a wholesale replacement.** `CheckIn_v2` sends
`keychains: [RuleKeychain]`; the Mac app assigns the received set wholesale per user and
rebuilds its filter index — no reconciliation, no caching by keychain/key ID. Therefore
synthetic keychains with stable-fake IDs at the API boundary are safe for **all** app
versions with **zero** version gating. The wire format stops being an input to the storage
decision at all: synthesizing keychains is the right transport answer regardless, so the
storage model should be decided purely on storage merits — and on those merits,
`BlockedMacApp` already proves the pattern. (`blockedApps` is, additionally, already sent
as its own first-class wire array — further precedent.)

**The legacy data is bounded and benign** (local task DB; proportions, not absolutes —
re-validate on prod before running the migration). Of 1,271 live skeleton single-app keys:

- **65%** sit in single-child keychains → trivial 1→1 fan-out.
- **30%** in private keychains attached to >1 child → overwhelmingly _one parent reusing
  their own keychain across their own children_ (47 keychains, 25 parents; the public,
  cross-family case is ~1.3%). Deterministic fan-out (one row per attached child)
  preserves behavior exactly and _upgrades_ them from a shared keychain schedule to
  independent per-child per-app schedules.
- **~1.3%** in public (admin-curated) keychains — the one deliberate exception, left
  intact.
- **~5%** orphan (keychain attached to zero children). Every one is in an _active_ account
  that still uses keychains — so "ignore" is the risky choice; they are retired too.
- **~0.9%** of all skeleton keys (≈12 keys / 8 children) have _any_ schedule. The primary
  justification for the synthetic-keychain illusion (per-app schedules) is vestigial in
  practice precisely because the only lever today is coarse — which the chosen model fixes
  natively.

## The decisions

1. **Correct-fix-as-storage, synthesis-as-transport, in a single PR / single deploy.** No
   transitional read-through lens is shipped. Confidence comes not from a temporal soak
   but from: **(A)** a pre-merge golden-diff of `CheckIn_v2`'s synthesized output
   (computed through the _real_ synthesis code path) over a prod snapshot, pre vs post,
   required-zero-behavioral-diff (keychain/key IDs excepted — the Mac app ignores them);
   **(B)** an in-migration equivalence assertion that aborts and rolls back on any
   per-child divergence; **(C)** soft-delete (not hard-delete) of retired keys, instantly
   reversible; **(+)** a wire pass-through that never stops honoring physically-present
   skeleton keys — which gives rollback-safety, the permanent public-keychain channel, and
   steady-state correctness from one mechanism with no public/private branching in the hot
   path. Atomic cutover has no dual-live window to reason about and is cleaner than a
   phased rollout.

2. **Parallel, not unified.** A new `UnrestrictedMacApp`, _not_ a unified
   `UserAppRule { mode }`. Keeps the already-shipped blocked path out of the blast radius;
   the two may legitimately diverge (notably: `UnrestrictedMacApp` must round-trip the
   exact `AppScope.Single` case — `.bundleId` vs `.identifiedAppSlug` — to faithfully
   reconstruct the wire `Key`, whereas `BlockedMacApp.identifier` is a loose string).
   Possible future unification is left to a later note.

3. **Public keychains stay app-capable; surfaced read-only (3a).** Only the admin creates
   public keychains. Their app grants keep flowing as real keychain keys and are surfaced
   **read-only / badged** in the dashboard apps view — not editable there. This is _not_
   the rejected lens: post-migration the only keychain-resident app keys are in public
   keychains, which the parent cannot edit anyway, so it is a degenerate, read-only, ~1.3%
   slice with no write-path. The pre-existing block-vs-unrestrict precedence (block wins
   when an app is both `BlockedMacApp`-blocked and skeleton- unlocked) is unchanged by
   this work and accepted as tolerable; 3a is what makes that conflict _visible_ to
   parents for the first time.

4. **One uniform retire rule (orphans folded in, not special-cased).** _Every skeleton key
   in a private keychain is retired (soft-deleted); those with attached children are
   fanned out to `UnrestrictedMacApp` first; orphans skip the fan-out and go straight to
   retire; public keychains are untouched._ Soft-deleting orphans is not merely safer — it
   is _more correct_ under the new model: reattaching a website keychain later should
   bring websites, not silently re-bypass the filter for a forgotten pile of apps the
   parent cannot see or manage in the new UI. No live behavior changes at migration
   (orphans reach no Mac app today).

## Scope boundary

Website keys are untouched. Private/personal keychains continue to exist and hold website
keys — they merely become app-key-free. We are carving the app dimension out of keychains,
not deleting keychains.

## Deferred (not blocking)

- Physically purging soft-deleted skeleton keys — a much later, non-urgent housekeeping
  step; the pass-through and `deleted_at` filter make the soft-delete the functional
  cutover.
- A longer-term position on app-keys inside public keychains (their own future note).
- Possible later unification of blocked/unrestricted into one `UserAppRule` if they stay
  symmetric.
- A regression test for the already-shipped no-Mac empty-state + drill-in redirects
  (predates this work; `02de8f51` shipped without tests).
- Pre-existing parent-ownership audit in several `Save*` resolvers (predates this branch).

A conceptual visualization of the before/after object graph was produced during design and
kept at
https://gertrude-dev.nyc3.digitaloceanspaces.com/scratch/app-skeleton-key-datamodel.html
