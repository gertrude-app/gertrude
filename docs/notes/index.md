# Decision notes index

Quick orientation for researching the _why_ behind past decisions, giving an overview of
all notes.

- **[001 — Mac app `domainRegex` keys to a real regex engine](./001-regex-keys-macapp.md)**
  — replaces a glob-masquerading-as-regex with `NSRegularExpression`/`RegExp` end-to-end
  (`caseInsensitive` on both); in-place upgrade rather than a new key type.

- **[002 — Throttling Mac app icon refreshes](./002-macapp-icon-refresh.md)** —
  icon-upload eligibility keyed on missing-or-stale freshness (version-aware preference
  for newer builds), not naive hash mismatch; adds `icon_uploaded_at` +
  `icon_source_app_version`.

- **[003 — Screenshot timer lifecycle](./003-macapp-screenshot-bursts.md)** — moves the
  Mac app screenshot timer out of a TCA `.cancellable(cancelInFlight:)` effect into a
  dependency-owned actor, eliminating the cooperative-cancellation window that allowed
  concurrent timers (cause of 10–12/sec screenshot bursts under Fast User Switching).

- **[004 — Stripe billing overhaul](./004-stripe-billing-overhaul.md)** — three-layer
  billing model (`BillingIdentity` / `StripeSubscription` / `BillingAccountSnapshot`)
  separating entitlement from billing substrate; kills the duplicate-customer and
  reactivation bug classes.

- **[005 — `vendorId` / `deviceId` / `installId` naming](./005-vendor-id-device-id-naming.md)**
  — naming convention for cross-app physical-device identity: `vendorId` only at the
  platform-API boundary (`identifierForVendor`), `deviceId` everywhere else, `installId`
  is a server-internal per-app install-row PK.

- **[006 — Capabilities derive from the billing snapshot](./006-capabilities-from-snapshot.md)**
  — capabilities are a union of entitlements from `BillingAccountSnapshot` (per-tier
  table), not the lossy `PlanStatus` projection; Medium-tier-ready by design.

- **[007 — Measuring marketing campaigns without a held-back cohort](./007-marketing-campaign-measurement.md)**
  — deliberately no holdout/A-B machinery (too few accounts for significance); instead
  throttle to manual daily waves, capture a `variant`, and read directionally from
  near-zero base rates + replies.

- **[008 — `child.claims` table and `ClaimIntent`: first-class claim model](./008-claims-table-and-intent.md)**
  — replaces three `ios_devices` columns with a dedicated claims table carrying a
  `ClaimIntent` enum; enables per-funnel intent verification and at-most-one-active-code
  enforcement.

- **[009 — Gertie shared Swift module structure](./009-gertie-shared-module-structure.md)**
  — semantic map of the shared Swift modules (`Gertie` / `GertieBlocker` / `GertieApp` =
  shared data; `gertie-tca-features` = shared TCA behavior) and the
  new-**target**-vs-new-**package** rule. Read before creating a new SPM module, or when
  unsure where to place shared functionality.

- **[010 — Music connection flow trades usability for App Store admission](./010-music-companion-app-claim-posture.md)**
  — the Gertrude Music claim flow is deliberately unhelpful (lands on login, never names a
  plan, ends on the dashboard root, claims devices for accounts that can't use them) to
  qualify for the 3.1.3(f) companion exemption after a 3.1.1 rejection. Read before
  "fixing" any of it.

- **[011 — Giving "app has unrestricted internet" a real home](./011-app-unrestrict-data-model.md)**
  — first-class child-scoped unrestricted-app model (near-mirror of the blocked-app
  model) replacing the emergent keychain/key projection; legacy keychain shape is
  synthesized back at the Mac-app wire boundary so the wire contract is unchanged.
