# 006 — Capabilities derive from the billing snapshot, not the `PlanStatus` projection

_Date: 2026-05-25._

Follow-up to [004](./004-stripe-billing-overhaul.md), which established `PlanStatus`
(display — "what does this account look like") and a separate `Capability` set (gating —
"what may it do") derived by "a single derivation switch" over `PlanStatus`. That switch
was the bug.

## The bug

A parent with a **paid, current Light subscription** who is **also trialing Full** was
denied iOS supervision. `BillingAccountSnapshot.planStatus` checks the trial before the
paid-Light fall-through, so the account collapses to `.fullTrial` — and `.fullTrial`
grants mac-app only (a Full _trial_ deliberately does not grant supervision; supervision
requires a paid sub). The paid-Light entitlement, which on its own grants supervision, was
silently dropped by the projection. (004 closed the _email_ version of this same "Light
user trialing Full" gap but not the capability version.)

Root cause: `PlanStatus` is a **lossy scalar** — one account, one case, with an
overlay-wins-over-substrate priority rule that is correct for a display label but wrong
for capabilities, which are the **union** of independent entitlements (paid sub ∪ trial ∪
complimentary). You cannot union a scalar.

## What changed

- `capabilities` now derives directly from the snapshot as a union, via a per-tier
  entitlement table (`StripeSubscription.Tier.capabilities`) for the live paid sub (when
  current) ∪ mac-app for a live Full trial ∪ both for complimentary. It no longer switches
  on `planStatus`. 004's "supervision capability matrix" (the switch over `planStatus`) is
  superseded.
- `PlanStatus.fullTrial`/`.fullTrialGrace` gained `substrate: PaidSubscription?` (a
  `{ tier, status }` struct), making the projection lossless for the trial-over-paid case
  so display consumers can stop reaching behind it.
- All five trial-aware consumers (panel copy, panel actions, parents-list, admin
  parent-detail, mac-app connection gate) now read `substrate` directly and gate on
  `substrate.status`, keeping display and actions consistent with the entitlement layer —
  any past-due substrate routes to fix-payment messaging, never the "paid Light"
  treatment.

## Key decisions

- **Fix at the snapshot, not by enriching the enum alone.** `Capability` is
  server-internal (never crosses the wire), so the capability fix has zero wire impact and
  belongs at the source of truth, not bolted onto a display projection.
- **Substrate is a struct (`PaidSubscription{tier,status}`), not a bare tier.** A **Medium
  tier is expected within ~6-8 weeks for Gertrude Music**, which makes the substrate's tier
  load-bearing (a Medium subscriber can trial Full → the substrate is Medium, not Light).
  Status is needed too, to distinguish a paying Light (grants supervision) from a past-due
  Light (grants nothing). A bare tier enum answers neither.
- **Per-tier capability table.** Adding Medium = one new arm, and the exhaustive `switch`
  fails to compile until it's handled. Avoids the combinatorial case-explosion that
  enriching the projection enum would cause across tiers.
- **Wire-safe / additive.** The discriminator stays `case: 'fullTrial'`; the new
  `substrate` field is additive, so no TS exhaustive switch breaks and old generated types
  ignore it. `PlanStatus` reaches only dashboard + admin (TS), never native apps;
  `PlanStatusV1` stays frozen and drops the substrate.
- **`PlanStatus` stays display-only.** Capabilities are now decoupled from it. We did
  _not_ redesign it into a structured `{ paid, trial }` model; the substrate field is the
  minimal lossless step — revisit only if Medium reveals more pressure.

## Open question

Trials are assumed **Full-only** for now, so the case names keep the `full` prefix. If
per-tier trials (e.g. trialing Medium) ever land, the _overlay_ itself needs a tier and
`fullTrial`/`fullTrialGrace` generalize to `trial(tier:, …)`.
