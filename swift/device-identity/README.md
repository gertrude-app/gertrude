# DeviceIdentity

Foreground device identity resolution shared by Blocker, Music, and Podcasts. This
package is not yet linked into any production app. It depends on Apple Security and
client-side dependencies, so it stays separate from the server-safe `gertie` package.

## Consumer contract

Create one `IdentityResolver` per app process on the main actor. Call
`resolveOnForeground()` synchronously before starting work that carries a device
identity. It performs local resolution only. A same-device transition returns `.adopted`
and publishes the shared identity as soon as the pending receipt is durable, so offline
startup can continue. Then call `reportPendingTransition()` asynchronously for `.adopted`
or `.retry`; do not make offline app startup wait for that call. Concurrent reports share
the in-flight request, and foreground resolution during a report uses its current local
identity without starting another resolution.

Failed reports retain the receipt and usable same-device identity. Retrying a receipt
publishes the current shared identity only when it agrees with the canary, including
after partial acknowledgement writes. Known migrations remain unavailable until
acknowledgement completes. Deferred reads leave the mirror untouched but expose no
identity from a new local resolution. Consumers must idle identity-dependent requests
when `deviceId` is nil; never fall back to a raw keychain read or live IDFV.

Supply `IdentityKeychainConfiguration` with the app's private access group and exact
existing identity account (including that app's debug suffix). App-memory reads, updates,
and deletion use the legacy account/class query without service, access-group, or
synchronization attributes. Writes update matching legacy items in place; absent items
are inserted using the configured private group and
`appMemoryService` (empty by default). Existing items keep their service and access group.
The new shared slots use a named service and `.dev` / `.sim` suffixes in debug builds.
Identity, canary, and receipt queries remain explicitly scoped and non-synchronizable.
Add the shared keychain entitlement during app adoption, keeping the app's private group
first.

The resolver takes these app-specific hooks:

- `metadata`: current app, model, OS version, app version, and live IDFV for reporting.
- `proofToken`: the token bound to the app's last server identity, captured before cleanup.
- `clearDeviceBoundState`: synchronously and idempotently clear device-bound credentials,
  carried-over connection state, and the Blocker controller's connected fast path. Throw
  if cleanup fails. This runs before migration persistence or reporting.
- `markMigration`: durably record that migration onboarding is required. Keep this marker
  until the walkthrough finishes, even after the pending report is acknowledged. Throw
  if persistence fails. A sibling's `.resolvedAsMigration` response also invokes cleanup
  and this hook before acknowledgement writes.
- `migrationPending`: read that durable marker. A pending same-device receipt can have
  already received `.resolvedAsMigration`; this prevents an offline restart from
  publishing its identity before acknowledgement has completed.
- `applyCredentials`: persist the returned child/token when present; throw on failure.
  A nil token grants no new credentials. Migration cleanup has already removed the old
  credentials before this callback runs.
- `publishIdentity`: update the app's identity mirror, including clearing it when nil.
  Ordinary foreground activation never clears the mirror; migration cleanup does.
- `report`: send the existing `ReportIdentityTransition` PairQL request. The package
  owns retry receipts; the app supplies its normal transport.
- `telemetry`: map typed anomalous events to app-specific event IDs and server labels.
  Events never include proof tokens. Healthy steady-state resolutions emit nothing.
  Acknowledgements confirming the locally adopted identity do not log adoption again;
  failures, migrations, child-conflict pins, and changes of identity remain visible.

Extensions must not instantiate the resolver or access the shared identity group. The
Blocker extension reads only the app-group identity mirror maintained by the app.

## Persistence and failure behavior

The shared identity migrates; its canary and each app's pending receipt are
`AfterFirstUnlockThisDeviceOnly`. App memory preserves the app's legacy identity slot.
Missing or undecodable identities are absent; other read errors defer resolution.
Temporary pending-receipt read errors defer too. A malformed or undecryptable receipt
emits telemetry. When the shared identity and canary are readable and agree, recovery
writes that identity to private app memory before deleting the bad receipt, then resumes
local resolution without reporting a transition. This deliberately loses the old-row
link; advancing private memory prevents an unverified report from restoring the old
supervised identity. Existing migration routing and cleared credentials are preserved.
Missing, mismatched, or unreadable shared slots defer recovery. Failed memory writes or
receipt deletion leave recovery retryable on the next activation.

Migration clears state before any persistence. If saving the receipt fails, the resolver
still attempts to mint the new identity and returns `migratedUnreported` when successful.
Failed acknowledgement writes retain the receipt and its original proof for the next
foreground attempt. Child-conflict pins update only private memory, leaving the shared
slots intact so a later activation can converge after ownership is corrected.

Holding a known migrated identity unavailable until acknowledgement is a deliberate
refinement of the original proposal: it prevents onboarding with the minted identity
before the server has resolved ownership. It does not gate same-device offline use.

## Tests

From `swift/`:

```sh
just nx-run-many 'test --projects=device-identity --output-style=stream --args="--jobs 4"'
```

Tests use controlled storage, Security operations, and transport; they do not touch the
login keychain, require signing, or contact the API. Signed-device verification of
entitlements, legacy key lookup, and restore behavior remains part of app adoption.
First verify that the new reader finds an identity written by the old app, then update
C and confirm both readers find the updated value with no competing item created.
