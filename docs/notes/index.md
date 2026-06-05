# Decision notes index

Quick orientation for researching the _why_ behind past decisions, giving an overview of
all notes.

- **[001 — Mac app `domainRegex` keys to a real regex engine](./001-regex-keys-macapp.md)**
  — replaces a glob-masquerading-as-regex with `NSRegularExpression`/`RegExp` end-to-end
  (`caseInsensitive` on both); in-place upgrade rather than a new key type.

- **[002 — Throttling Mac app icon refreshes](./002-macapp-icon-refresh.md)** — icon
  upload eligibility now keyed on missing-or-stale freshness (with version-aware
  preference for newer app builds), not naive hash mismatch; adds `icon_uploaded_at` +
  `icon_source_app_version` to `macos.mac_apps`.

- **[003 — Screenshot timer lifecycle](./003-macapp-screenshot-bursts.md)** — moves the
  Mac app screenshot timer out of a TCA `.cancellable(cancelInFlight:)` effect into a
  dependency-owned actor, eliminating the cooperative-cancellation window that allowed
  concurrent timers (cause of 10–12/sec screenshot bursts under Fast User Switching).

- **[004 — Stripe billing overhaul](./004-stripe-billing-overhaul.md)** — three-layer
  billing model (`BillingIdentity` / `StripeSubscription` / `BillingAccountSnapshot`),
  action-based subscription panel (`primary`/`secondary` from the server), reconciling
  webhook; fixes the duplicate-customer and reactivation classes of bugs by separating
  entitlement from billing substrate.

- **[005 — `vendorId` / `deviceId` / `installId` naming](./005-vendor-id-device-id-naming.md)**
  — naming convention for cross-app physical-device identity: `vendorId` only at the
  platform-API boundary (`identifierForVendor`), `deviceId` everywhere else, `installId`
  is a server-internal per-app install-row PK.

- **[006 — Capabilities derive from the billing snapshot](./006-capabilities-from-snapshot.md)**
  — capabilities come from `BillingAccountSnapshot` as a union of entitlements (per-tier
  table), not the lossy `PlanStatus` projection; `substrate: PaidSubscription?` added to
  trial cases to make the projection lossless; Medium-tier-ready by design.

- **[007 — Measuring marketing campaigns without a held-back cohort](./007-marketing-campaign-measurement.md)**
  — deliberately no holdout/cohort or A/B machinery: at ~800 accounts / ~117 backlog a
  control arm can't reach significance, so we throttle (manual waves, daily cadence),
  capture a `variant` for copy reconstruction, and lean on near-zero base rates + replies
  for directional, judgment-based reads.
