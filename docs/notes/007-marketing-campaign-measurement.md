# 007 — Measuring marketing campaigns without a held-back cohort

_Date: 2026-06-05._

## What we changed

The automated marketing system measures campaigns with a deliberately thin layer: a
`variant` column on `parent.marketing_email_sends` (plus the row's existing `parent_id` /
`campaign` / `created_at`), and nothing else. There is **no** treatment/control holdout,
no cohort-assignment table, and no concurrent A/B machinery.

`mac_setup_24h` (activation) runs on the scheduled job, which was also dropped from hourly
to once daily. `ios_only_mac_trial` (upsell) is registered **only** in
`manualMarketingCampaigns` and is sent by hand in `limit`-capped waves via the
`SendMarketingCampaign` super-admin endpoint, so it cannot auto-fire against its backlog
while the copy is still being tuned. Idempotency stays `(parent_id, campaign)` — one email
per parent per campaign.

## Why

The original instinct was a textbook held-back cohort: withhold the email from a random
slice of eligible parents and compare later Mac-trial starts / Mac connections /
subscriptions between groups. At our scale that is theater. The whole product has ~800
accounts; the `ios_only_mac_trial` backlog is ~117 parents. A 50/50 split of 117 leaves
~58 per arm, which can only detect about a 5x swing in conversion at normal confidence —
no email moves the needle that hard. So a holdout could never reach statistical
significance for any realistic effect, and a concurrent copy A/B is even more
volume-hungry (the gap between two decent variants is smaller than the gap between "email"
and "silence").

Holding back also has a real cost when the audience is this small and non-replenishing:
you forfeit conversions from a scarce pool to buy a base-rate estimate that is itself
hopelessly noisy at n≈20–60.

What we rely on instead: the `ios_only_mac_trial` audience is _dormant by construction_
(eligible 7+ days, never started a Mac trial), so its organic forward-conversion rate is
near zero — which means a visible lump of conversions after a wave is attributable to the
email by ordinary judgment, no control group required. The `variant` column lets us
reconstruct which copy was live for a given send so outcomes can be grouped by version
after the fact. And because these are personal, reply-to-Jared emails, the **replies** are
the richest signal at this size — qualitative learning beats a quantitative test we can't
power.

So the real job of this layer is not to prove causal lift. It is to (1) throttle a scarce
audience so we don't burn the backlog on unproven copy, and (2) capture enough — variant +
timestamps — that we can eyeball outcomes and read replies. Measurement here is a judgment
call fed by signal, not a verdict from a test.

## Tradeoffs

We give up any clean causal read on lift, and any clean v1-vs-v2 comparison: variants are
swapped sequentially (bump the campaign's `variant`, redeploy, send the next wave), so a
cross-variant difference is confounded by time and by which slice each version reached —
v1 drains the backlog, v2 mostly sees fresh flow. Treat those diffs as directional only.

The manual routing for `ios_only_mac_trial` means a human has to drive each wave; that is
intentional during the learning phase. When the copy settles, automating it is a one-line
move: add `IosOnlyMacTrialCampaign()` to `scheduledMarketingCampaigns`. If the userbase
ever grows by an order of magnitude, a real held-back cohort becomes worth building and
this decision should be revisited.
