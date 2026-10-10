# DeviceIdentity

Foreground device identity resolution shared by Blocker, Music, and Podcasts. Blocker and Music
now consume the package; Podcasts adoption remains pending. It depends on Apple
Security and client-side dependencies, so it stays separate from the server-safe `gertie` package.

## Consumer contract

Create one `IdentityResolver` per app process on the main actor. Call
`resolveOnForeground()` synchronously before starting work that carries a device
identity. It performs local resolution only. A same-device transition returns `.adopted`
with the identity bound to the app's existing credentials, or the receipt's original
source identity when unconnected. The app and extension keep using that identity while
the report is pending; they do not switch to the shared destination prematurely. Then
call `reportPendingTransition()` asynchronously for `.adopted` or `.retry`; do not make
offline app startup wait for that call. Concurrent reports share
the in-flight request, and foreground resolution during a report uses its current local
identity without starting another resolution.

Failed reports retain the receipt and usable same-device identity. Retrying a same-device
receipt reads `credentialDeviceId` again, so a partial acknowledgement that advanced C
before credential saving failed keeps the old connection usable, while a successful
credential save followed by receipt-deletion failure uses the new connection. The durable
ThisDeviceOnly receipt preserves the source identity and original proof; retries do not
infer the working identity from partially updated A/B/C slots. Known migrations remain
unavailable until
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
- `credentialDeviceId`: the identity bound to the currently persisted credentials, or nil
  when unconnected. Read the saved credential record, not keychain C or the shared slots.
- `clearDeviceBoundState`: synchronously and idempotently clear device-bound credentials,
  carried-over connection state, and the Blocker controller's connected fast path. Throw
  if cleanup fails. This runs before migration persistence or reporting.
- `markMigration`: durably record that migration onboarding is required. Keep this marker
  until the walkthrough finishes, even after the pending report is acknowledged. Throw
  if persistence fails. A sibling's `.resolvedAsMigration` response also invokes cleanup
  and this hook before acknowledgement writes.
- `migrationPending`: read that durable marker; throw if it cannot be read so resolution
  defers without clearing device-bound state. A pending same-device receipt can have
  already received `.resolvedAsMigration`; this prevents an offline restart from
  publishing its identity before acknowledgement has completed.
- `applyCredentials`: persist the returned child/token and its device ID together as one
  credential record; throw on failure. `credentialDeviceId` must reflect whichever record
  was actually saved, even if this hook throws after saving. A nil token grants no new
  credentials; discard an existing connection if its identity differs from the response.
  Migration cleanup has already removed the old credentials before this callback runs.
- `publishIdentity`: update the app's identity mirror, including clearing it when nil.
  Ordinary foreground activation never clears the mirror; migration cleanup does.
- `report`: send the existing `ReportIdentityTransition` PairQL request. The package
  owns retry receipts; the app supplies its normal transport.
- `telemetry`: map typed anomalous events to app-specific event IDs and server labels.
  Events never include proof tokens. Healthy steady-state resolutions emit nothing.
  Acknowledgements confirming the locally adopted identity do not log adoption again;
  failures, migrations, child-conflict pins, and changes of identity remain visible.

Extensions must not instantiate the resolver or access the shared identity group. The
Blocker extension prefers the app-group identity mirror maintained by the app. Before
first app activation after an update, a missing mirror with no migration marker permits
read-only fallback to the stored connection’s device ID, or the legacy private keychain
ID when unconnected. Extensions never freeze a new IDFV. Publishing a nil mirror records
the migration marker before removing the mirror, disabling this fallback during cleanup.
A published mirror takes precedence even while the migration walkthrough remains pending;
once present, the extension deletes its legacy keychain copy.

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
