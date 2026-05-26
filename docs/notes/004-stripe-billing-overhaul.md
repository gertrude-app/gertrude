# 004 — Subscription / billing overhaul: layered model, action API, reconciling webhook

_Date: 2026-05-18._

_EDIT:_ see also [006](./006-capabilities-from-snapshot.md) for a related follow-up.

## What we changed

The conflated `Plan` enum and the URL-dispenser dashboard channel are gone. Billing is now
three explicit layers:

- **`BillingIdentity`** (Duet model, `parent.billing_identities`, 1:1 with any parent that
  has billing history) — lifetime parent facts that survive lapse and reactivation:
  `stripeCustomerId`, `fullTrialStartedAt`, `lastStripeSubscriptionId`, `lastPaidTier`,
  `trialEmailLifecycle`, `isComplimentary`.
- **`StripeSubscription`** (Duet model, renamed from `Subscription`;
  `parent.subscriptions` → `parent.stripe_subscriptions`) — the live Stripe substrate.
  After the cleanup migration every surviving row represents a live sub
  (`active|trialing|past_due`) with `stripe_id`, `stripe_status`, `current_period_end` all
  `NOT NULL`. Terminal and standalone-trial state no longer lives here — it moved to
  `BillingIdentity`.
- **`BillingAccountSnapshot`** — a point-in-time aggregate value (not a row) of
  `(billingIdentity?, stripeSubscription?, date)`. It derives `planStatus`, `capabilities`
  / `can(_:)`, `monthlyPrice`, and the mac-app access UX state in one place.

Status is clock-derived and never persisted. `PlanStatus` (`.free`, `.light(status:)`,
`.full(status:)`, `.fullTrial(until:)`, `.fullTrialGrace(until:)`, `.complimentary`, with
`BillingStatus = .current | .pastDue`) answers "what does this account look like"; the
separate `Capability` enum answers "what may it do." The dashboard no longer infers
anything: `GetSubscriptionPanel` returns a structured `primary`/`secondary` `Action` set
and the UI owns the copy. Light → Full now routes through `UpgradeSubscriptionTier`
(`subscriptions.update`), never a second checkout. The webhook handler became a
reconciler: hard idempotency, price-id reconciliation, duplicate-overwrite guard, ops
alarms, transaction-wrapped.

`Plan`, `BillingStatus.Db`, `StripeUrl_v2`, the `?plan=full` query param, and the 8-branch
dashboard link-text logic are all deleted. No shim, no adapter, no compatibility surface.
Verified: no installed iOS/Mac app consumes `Plan` — the refactor is server + dashboard +
admin only.

## The two incidents that forced this

**J. Sparks (the originating bug).** Paid for Light ($10/yr legacy). ~2 months later
completed a _second_ checkout for Full ($10/mo). The checkout session was built without
his existing Stripe customer, so Stripe — which deduplicates customers on _nothing_, not
even email — created a brand-new customer and subscription. The webhook blindly overwrote
the stored `stripe_id` to point at the new Full sub. The old yearly Light sub kept
silently billing under the now-orphaned customer because nothing canceled it and we no
longer had a pointer to it. One parent record, two customers, two simultaneously-billing
subs.

**Sebastian J.** Brand-new parent paid, canceled within minutes (setup confusion), then
could not self-serve renew — Jared had to manually "reset state" and refund.

Same root cause. The system had **no concept of conversion or reactivation**: every paid
transition (signup, trial, reactivation, tier change) was modeled as a fresh sale through
one tool — "create a checkout session" — and the webhook trusted whatever sub id arrived.
There was no customer-side path that _could_ do the right thing for an upgrade, because no
such path existed.

## Why a deep refactor instead of more edge-case patches

A previous attempt patched within the existing structure and surfaced an ever-expanding
set of edge cases. That expansion was the signal. Stepping back, two structural faults
explained all of it:

1. **The workflow was shaped like the old single-product world.** "Current plan → either a
   checkout URL or a portal URL" works when there is one product and one transition (free
   → full). Light + Full multiplies the states; some transitions are checkout sessions,
   some are portal sessions, and some are direct `subscriptions.update` calls with no URL
   at all. They are not variants of "give me a Stripe URL."
2. **`Plan` did two jobs at once** — _entitlement_ ("what the user can use") and _billing
   substrate_ ("what Stripe object backs it"). `fromLight` was the tell: a Light
   subscriber mid-Full-trial was `.full(.trialing(.fromLight))`, correct for entitlement
   but actively misleading for billing actions (the underlying Stripe sub is still Light
   and must be _updated_, not re-bought). The discriminator that carried the routing
   answer was being recorded and then ignored — UI and resolvers treated all
   `.full(.trialing)` states identically.

Separating the two concepts and moving action computation server-side is the fix. The
defensive guards are belt-and-suspenders against races (duplicate tabs, replays, ops
intervention); the routing change is the actual fix.

## The implicit contract, now made explicit

Nowhere written down before; the work makes it structural:

1. One parent ↔ one Stripe customer, forever. Reuse on every transition.
2. `stripe_id` is the canonical pointer to the current sub. Overwriting it requires
   _evidence the previous sub is dead._
3. Lapsed states preserve `stripe_id` for **customer reuse**, not for billing.
4. Tier change on a live sub → `update`. Tier change on a dead/absent sub → `checkout`
   with the existing customer id passed in.
5. The webhook is the auditor of last resort, not the source of truth.
6. Every consumer of billing state owes an exhaustive map; there is no safe default.

The one-parent-one-customer invariant is now enforced by schema composition:
`stripe_customer_id` on `billing_identities`, a FK from `stripe_subscriptions` to it, and
CHECKs (`customer_id_required_when_history_present`, `complimentary_has_no_stripe_state`)
installed `VALID` from the additive migration.

## Alternatives considered and rejected

- **Clear `stripe_id` on cancellation** (the natural-sounding early fix, to stop the
  duplicate guard ever seeing a stale id). Rejected, and the reason is non-obvious: the
  lapsed states carry the old `stripe_id` _specifically so we can reuse the Stripe
  customer when the parent returns._ Clearing it makes every lapsed customer a
  duplicate-creation candidate on next checkout — the original bug under a new trigger.
  The guard belongs at the overwrite site, not the storage site.
- **Split status into a pure 3-state tier enum + a billing-posture type**, so permission
  code could ask one simple question. Rejected: _a free trial of Full does not grant iOS
  supervision_ (supervision strictly requires a paid sub). No 3-state tier enum can answer
  a universal "what can they do" — the answer is per-feature. Hence `PlanStatus` keeps the
  trial/grace/comp cases, and gating moved to a separate `Capability` set with a single
  derivation switch.
- **Enforce one-trial-per-parent in the schema.** Considered overloading
  `fullTrialStartedAt` (set on first paid Full at 4 sites — implemented and reverted) and
  a separate `everPaidFull` boolean + backfill. Both rejected: the violation (a parent who
  paid Full directly, lapsed, then claims a trial) costs ~$7, the path is already flagged
  anomalous by an existing `unexpected` alarm, and the population is tiny. A lightweight
  `InterestingEvent` gives telemetry; revisit only if volume surprises us.
- **Eagerly create the Stripe Customer at trial start.** Rejected: ~71% of historical
  standalone trials never convert (431/608 rows in a pre-deploy prod-snapshot audit);
  eager creation produces a long tail of orphan customers with no payment method. Customer
  creation defers to first `StartCheckoutSession`.
- **A `cancelFullTrial` action.** Dropped: no-card trials don't bill, so there is nothing
  to cancel — the lapse is just the absence of action. Adding it would force inventing
  state (`trialCanceledAt`?) and answering restart-policy questions for negligible UX
  benefit.
- **Always-expanded action buttons / modal close-X panel UX.** Rejected for a calm
  tri-state panel (resting → manage → compare): the status badge color carries urgency;
  the user opts in to "Manage plan…". Free is framed as a legitimate end state (real
  product value via Gertrude Blocker), not an upsell surface.

## Decisions worth not re-litigating

- **Naming.** `BillingAccountSnapshot` is named for its _use_ (answers account-level
  questions). `PlanStatus` is the display/status concept — _not_ "Entitlement," which
  collides with capability vocabulary. `BillingStatus.current` (not `.good`/`.paid`) is
  the accounting term that pairs with `.pastDue` and stays correct for trialing subs. The
  snapshot is point-in-time: its `date` is frozen at construction — correct for request
  scope, stale if held across a background job.
- **Two predicates on `StripeSubscription`, one source of truth.** `isPaying`
  (`.active|.pastDue`) = "money flowing now," used by the daily failsafe. `isLive`
  (`.active|.trialing|.pastDue`) = "a Stripe object backs access," used by entitlement
  derivation and the duplicate guard. `.trialing` is in `isLive` defensively even though
  we never pass `trial_period_days` (Stripe trials unused; trial state lives on
  `BillingIdentity.fullTrialStartedAt`). Reuse these; do not reintroduce hand-coded status
  lists.
- **Duplicate-overwrite policy** (at the overwrite site): existing sub
  `active|trialing|past_due|incomplete` → reject + alarm;
  `canceled|unpaid|incomplete_expired` → allow; 404 → allow; any other Stripe error →
  **reject (fail closed)** — a transient lookup error is not evidence the old sub is dead.
- **`subscriptions.update` post-update validation.** Only `active` or `past_due` accepted;
  anything else fails loudly with a `notifyPostUpdateStatusAnomaly` alarm rather than
  silently persisting "paid."
- **Webhook idempotency before processing** is accepted as imperfect: a crash between the
  idempotency insert and the handler poisons Stripe's retry. Volume is a few/year and the
  daily Stripe failsafe (`current_period_end + 2d`) self-heals drift. The handler is
  `db.withTransaction`-wrapped (not `db.transaction`, which severs
  `@TaskLocal`/`@Dependency` propagation).
- **Supervision capability matrix** (the load-bearing business rule): `.complimentary` /
  `.full(.current)` → supervise + mac; `.light(.current)` → supervise only; `.fullTrial` →
  mac only; `.free` / `.fullTrialGrace` / `.full(.pastDue)` / `.light(.pastDue)` →
  nothing. Past-due Light denies supervision (this reversed an earlier "allow light
  past-due" call).
- **Trial = 21d + 7d grace**, clock-derived from `(fullTrialStartedAt, now)`. Email
  lifecycle advances `none → ending_soon_sent → expired_sent → final_sent` (plus a
  `skipped` terminal for "paid Full / no longer applies"), **send-first then
  write-lifecycle** — a rare duplicate warning beats a silent miss or a ton of defensive
  enterprisy code. A uniform predicate over standalone-trial and from-Light-trial parents
  closes the pre-existing bug where Light users trialing Full got no trial-ending email.
- **Pre-deploy migration verification** (608-row prod snapshot): 123 rows survive, ~71%
  are expired standalone trials, 0 duplicate customers in the snapshot, 0 local↔Stripe
  drift. One real edge caught and fixed before deploy — a complimentary parent (Olivia H.)
  holding a stale `stripe_id` from a prior paying period would violate
  `complimentary_has_no_stripe_state`; the additive migration's step-0 self-heal nulls
  that `stripe_id` (fires once in prod, zero times in clean envs).

## Consequences and what could still go wrong

- **Pre-existing duplicate-customer victims are not healed.** Out of scope; tracked for
  separate manual cleanup. This refactor prevents new ones; it does not repair history.
- **The light-tier portal config is an opaque Stripe `bpc_…` id** that prohibits proration
  on customer-initiated cancel (a historical refund policy). If it is ever deleted or
  recreated in Stripe, the code silently falls back to the default config and the
  proration-prohibition is lost. No test catches this.
- **The duplicate guard relies on `existing != incoming` string id inequality.** Fine
  today; would break if Stripe ever reused sub ids across customers.
- **Snapshot staleness**, the email double-send window, and the generator-to-deploy gap
  are each individually accepted with explicit mitigations above.
- A `.complimentary` parent must never enter a payment flow; guards exist at the known
  entry points but an exhaustive audit was not done.

## Deferred / out of scope

- **Duet atomic upsert primitive.** The ~4 hand-rolled `INSERT … ON CONFLICT` sites
  (StripeEvent idempotency among them) are a real smell but the fix is tracked as a
  separate follow-up, not part of this PR.
- **Down-conversion (Full → Light) for active paying users**, family/multi-tier plans, and
  redesigning the light portal config — architectural readiness yes, product features no.
