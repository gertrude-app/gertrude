# 013 — Shared iOS device identity (`DeviceIdentity`)

_Date: 2026-10-01._

## The problem

Every Gertrude iOS app (Blocker, Music, Podcasts) froze `identifierForVendor` on first
launch into its **own private keychain item** and used it as `deviceId`, the primary key
of `child.ios_devices` (see [005](./005-vendor-id-device-id-naming.md)). That storage is
wrong in two opposite directions:

- **Too private (#913).** If all Gertrude apps are deleted, IDFV rotates. Each app's
  frozen copy survives in the keychain, but an app installed _after_ the gap freezes the
  new IDFV. Siblings diverge: one physical phone, two or three device rows.
- **Too portable (migration).** Keychain items and app-group storage migrate to a new
  iPhone via Quick Start or encrypted backup. The new phone presents the old phone's
  `deviceId`: two physical phones, one row. The server sees a device that is already
  supervised (the old phone genuinely is), so the new phone is denied the supervision
  walkthrough. The app detects the disagreement but routes to `promptInstallProfile`,
  which can never succeed on an unsupervised phone. The first real case was a customer
  stuck in that loop for days, eventually creating a second account to escape it.

Both are one defect: a single software identifier held in storage whose lifetime doesn't
match the question being asked. Apple exposes no hardware identifier, so the fix is
storage whose lifetime does match.

## The design

A shared SPM package, `DeviceIdentity`, linked by all three apps. It owns every identity
keychain read and write. **Apps get identity only from its resolver**; `deviceId()`
returns the resolved id or nil, never a raw keychain value.

### Storage

| slot | where | accessibility | migrates? | meaning |
| --- | --- | --- | --- | --- |
| **A** identity | shared group `WFN83LM943.com.netrivet.gertrude.identity` | `AfterFirstUnlock` | yes | the `deviceId` all apps share |
| **B** canary | shared group | `AfterFirstUnlockThisDeviceOnly` | **no** | copy of A that can't leave this hardware |
| **C** app memory | each app's existing private item | unchanged | yes | the id this app last used with the server |
| pending | per app, private | `AfterFirstUnlockThisDeviceOnly` | no | an unacknowledged transition report |

The key fact: on a new phone, **A arrives and B does not**. This was verified on
hardware before building anything. A direct Quick Start (iPhone SE to iPhone 11) carried
A intact and B was `errSecItemNotFound`. Restoring the SE from its own encrypted backup
kept both, so restoring a phone from its own backup isn't mistaken for a migration.

Every item is non-synchronizable with an explicit service and access group, and every
`SecItem*` status is checked. Reads are three-valued: `.value`, `.absent` (not found or
undecodable), or `.unknown` (locked, missing entitlement, any unrecognized status).
`.unknown` defers all identity work; it is never guessed into `.absent`, because that
would turn a locked keychain into a false migration.

### Resolution rules

Run on foreground activation only, before any request carrying a device id:

0. **A pending report exists** → retry it first, before the rules below. If it was a
   migration, re-clear device-bound state (idempotent).
1. **A absent** (shared layer never ran on this hardware) → seed from C, else live IDFV,
   else a new UUID. Write B, then add A add-only so racing siblings can't both win.
   Seeding from C means existing installs keep the id the server already knows.
2. **A present, B absent or ≠ A** → **migration.** Clear device-bound state _first_,
   mint a new id Z, save a pending `migrated` report carrying the old token as proof,
   then write B and A. Clearing before any write means every later failure degrades to
   "onboard as a new phone," never to presenting the old id.
3. **A = B, C absent** → a sibling set up identity on this phone; adopt A.
4. **A = B = C** → steady state; do nothing.
5. **A = B, C ≠ A** → this app used a different id on this same phone (#913). Report
   `sameDevice` and adopt the server's answer.

### The server side

One unauthenticated, proof-gated pair, `ReportIdentityTransition`, and one table,
`child.ios_device_transitions`. The proof is a token issued to the old row's install; no
child or token is returned unless it verifies. The response's `reason` tells the client
what to do:

- `normal` / `supervisionCanonical` → write the returned id to B, A, then C. For
  `sameDevice`, the row with a supervision record wins.
- `resolvedAsMigration` → a sibling already recorded a verified migration for this pair.
  Same writes, **plus** the same clearing and new-phone routing as a first-app
  migration. This is what makes launch order irrelevant: whichever app opens first after
  a transfer does the migration, and the others get it from the server.
- `childConflictPin` → the rows belong to different children. Write C only and keep
  reporting each launch until support resolves the data.

**The server only adds.** Device rows, installs, supervision records and tokens are
never deleted, repointed or merged by a transition. Every legacy id keeps naming a live
row, so the ~20 unauthenticated resolvers that take a device id need no aliasing.
Duplicate rows become a presentation concern for the parent-facing UI, which isn't built
yet.

### What each app clears on migration

- Blocker: account connection, pending supervision code, protection mode. It also keeps
  an app-group mirror of the resolved id for its extensions, which never run the
  resolver. Then it routes to the supervision walkthrough instead of the old dead end.
- Music: its connection.
- Podcasts: its token (keeps PIN and install date).

## Alternatives rejected

- **Merging duplicate rows** (alias table, canonical-id lookups in every resolver,
  finalization jobs). Specified in full and attacked over four adversarial review rounds;
  nearly every critical finding came from the machinery needed to _safely delete_ the
  merged row. Never deleting removes that whole class of problems at the cost of
  duplicate rows the UI has to badge.
- **Repairing torn canary/identity states, cross-app pending slots, detach flags.**
  Each kept introducing unbounded failures to fix bounded, freak-rare ones. A spurious
  re-mint costs one extra row and, for a supervised Blocker, one re-supervision prompt.
- **App Attest / DeviceCheck as the hardware anchor.** Heavier, and unnecessary once the
  canary behavior was confirmed on hardware.

Each deferred mechanism has a numeric telemetry trigger that would justify reviving it
(e.g. readable `B ≠ A` on ≥5 devices in 90 days). The client logs anomalous outcomes
only: migrated, adopted, deferred, canary mismatch, novel keychain statuses.

## Known limits

- Phones that migrated **before** these app versions ship still share one id. They
  can't be detected and are fixed by hand.
- Nothing changes on a device until each app is updated and opened at least once.
- One phone claimed to two children can't be represented; it stays pinned and visible.
- Under-18 / Family Controls re-authorization on migrated hardware is unanalyzed.
