# iOS Shields (ManagedSettings) — Protocol Extension

> **STATUS: DRAFT — not implemented.** Extends `docs/ios-recording-protocol.md` to
> close the persistent-socket leak. Invariant S1′ below is expected to be VIOLATED by
> the current shipped design; the sim models the leak (OS RULE R13) and the explorer
> demonstrates it. Nothing in this doc is normative until the shield actuator lands.

## The leak this closes

NE flow verdicts are final per socket: once the filter `allow()`s a flow, subsequent
data on that connection never re-consults the filter. A connection opened during a
recording-backed suspension (a YouTube HTTP/2 or QUIC connection, say) keeps carrying
data after the recording stops and blocking "resumes" — the child retains a partially
working app with no evidence flowing. Observed on device during the spring 2025
experiment (YouTube remained moderately functional post-suspension); confirmed as the
principal reason the feature was backed out. There is no socket-level fix available to
the extension: existing flows cannot be enumerated or killed, and holding every
suspension-era flow in data-verdict/peek mode indefinitely is unproven and
memory-prohibitive in the filter's budget (considered, rejected unless measured
otherwise).

Since the leak cannot be closed at the socket layer, it is closed at the
app-usability layer: ManagedSettings application shields. Steady state is shields UP
on every app except a parent-chosen allowlist; a live suspension drops them; the end
of evidence raises them again, making leaked sockets moot because the child cannot
use the app. This is the design Living Room (Chris's fork) shipped on — precedent
that the whole shape works in production.

## New protocol elements

| Element | Kind | Writer(s) | Readers | Semantics |
| --- | --- | --- | --- | --- |
| shield allowlist | register (group disk) | app (from parent config) | app, controller | opaque `ApplicationToken`s of never-shielded apps; pickable only on the child's device (`FamilyActivityPicker`) |
| shield state | **actuator** (named `ManagedSettingsStore`) | app (entry edge) + controller (reconciler) | the OS | persists across process death AND reboot until overwritten — this is not a register we read back so much as device policy we must keep reconciled |

The shield actuator is the protocol's first element with **inverted fail-safe
polarity**. Flow blocking fails safe by inaction: the next flow re-derives. Shields
fail *dangerous* by inaction: whoever dropped them must ensure something raises them,
and the dropped state survives everything including reboot. The cure is the same
discipline as D2/D7 — shield state is a **level-triggered reconciled projection of
`live()`**, never an edge:

```
shieldsDerived(now) = live(now) ? down : up     // for non-allowlisted apps
```

- **Controller (primary reconciler, D8):** on every flow it receives and at startup,
  compare derived state to last-written state; write when they differ. The controller
  is the right home: less sandboxed than the filter, relaunched by the OS at boot
  (R6), reliably granted CPU while traffic flows, and ManagedSettings writes from the
  control provider are already prototype-proven under both authorization paths
  (Jared, 2026). Startup reconcile covers reboot-with-shields-down.
- **App (entry edge):** drops shields at `broadcastStarted` alongside writing the
  expiration. This edge is NOT optional — see the entry deadlock below.
- Two writers to one store deliberately violates the single-writer rule; it is safe
  only because both compute the same idempotent projection from the same registers
  and writes reconcile toward it (last writer converges). No other writer may exist.

## The traffic-coupling hazard (why entry/exit differ)

Shields suppress the very traffic that grants the protocol CPU. A shielded app
generates no user-initiated flows, so:

- **Entry deadlock:** if shield-drop waited on a controller flow-reconcile, the kid
  could never wake a shielded app to generate the flow. Entry must come from the app,
  which is foreground at "start recording" anyway.
- **Exit starvation:** raising shields relies on *some* post-suspension traffic
  (allowlisted apps, background refresh, the Gertrude app, the leaked connection's
  app opening any new socket). Believed adequate in practice; the explorer must probe
  it rather than assert it. If starvation is real, the escape hatch is a
  `DeviceActivityMonitor` schedule as a traffic-independent CPU source — but that is
  another extension target (n+1 again) and is a last resort the sim must justify.

## Invariants (extending S1/S2/L1-L3/C1)

- **S1 (rescoped, honesty):** S1 governs NEW flows only. It says nothing about data
  on connections verdicted before blocking resumed. The composite below is the real
  parent-facing property.
- **S3 (shield safety):** whenever `¬live()` persists beyond `shieldLatency` (bound
  TBD: reconcile trigger + write time), every non-allowlisted app is shielded.
- **L4 (shield liveness):** while `live()`, shields are down within `shieldLatency`
  of entry (UX: the kid can actually use the granted suspension).
- **S1′ (composite, the point of it all):** no *usable* data path for a
  non-allowlisted app while unrecorded beyond the latency bound — new flows blocked
  (S1) AND the app shielded (S3). Leaked sockets exist but are unusable.
- **C1 (extended):** convergence additionally requires shields up.

## Failure matrix (additions)

| Failure at t | Required behavior |
| --- | --- |
| process dies between shield-drop and raise | controller reconciles on next flow/startup; bounded by traffic + `shieldLatency` |
| reboot mid-suspension (shields down, persisted) | broadcast died → `¬live()` → controller startup reconcile raises shields (R6 guarantees launch) |
| connection opened during suspension, used after | new flows blocked (S1); app shielded (S3) makes the socket unusable (S1′); socket itself dies at reboot only |
| allowlist edited mid-suspension | next reconcile applies it; no special casing |
| Screen Time authorization revoked | filter + shields both die — device reverts to unprotected; app must detect and re-onboard (same class as filter removal today) |
| shielded app generates zero flows post-suspension | exit-starvation: reconcile delayed until ANY traffic; explorer probes whether this is reachable in realistic action mixes |

## Authorization (platform knowledge, 2026-07)

Two proven paths (both prototyped by Jared in spike apps):

1. **Unsupervised child:** child under 18 in an Apple Family — solid, standard
   FamilyControls story.
2. **Supervised adult:** individual-style Screen Time grant on a supervised device —
   proven to work. **Sharp edge:** iOS 26 below ~26.4 has a bug where apps granted
   Screen Time access can be revoked using the DEVICE passcode instead of the Screen
   Time passcode. For the accountability use-case (adult self-restricting; spouse or
   partner holds the ST passcode) those versions are UNSAFE: the user can strip the
   grant themselves. Fixed in later iOS 26 releases. Shipping gate: detect and warn
   on (or refuse) affected versions for supervised-adult installs; pin down the exact
   fixed build during the conformance spike.

## Known bounded leaks (named now, not discovered later)

- **Safari/web:** Safari is presumably allowlisted (or the device loses browsing),
  so a web-YouTube socket opened during suspension leaks post-suspension with no app
  shield to catch it. `shield.webDomains` may cover it — conformance question. Until
  then: known, bounded (dies at reboot/network transition; new page loads are S1-blocked).
- **Background audio:** whether shielding halts already-playing background audio is
  unverified — conformance question.

## Interaction with restart-within-grant

Jared leans yes (2026-07-04). Shields make it cleaner, not harder: if the grant is
register-authoritative (D7 already forced this) and shields are a projection of
`live()`, restart-within-grant falls out — a lock finishes the broadcast, `live()`
fails, shields rise on reconcile; the kid restarts the recording within the grant,
`live()` holds, shields drop again. No app-side grant state machine required. The
app-side grant-consumption logic (`broadcastFinished` clearing the register) is what
would change; decide when implementing.

## Sim model requirements (honesty clause)

- **R13 — flow verdict finality / socket persistence** *(landing with this doc)*:
  an `allow()`ed flow becomes a persistent connection; data over it never consults
  the filter; connections die at reboot. Lets the explorer demonstrate S1′ violation
  against the CURRENT design — the motivating counterexample.
- **R14 — ManagedSettings persistence** *(with implementation)*: shield state as
  world state surviving process death and reboot; written only by authorized
  processes (app, controller).
- **R15 — shields gate app usability** *(with implementation)*: user-initiated flows
  and socket use from a shielded app do not happen; background-refresh traffic may.
  This coupling is what lets the explorer find entry-deadlock/exit-starvation.

## Conformance spike questions (device, before implementation)

1. Controller-written `ManagedSettingsStore`: reliability, write latency, behavior
   under both auth paths (child + supervised adult).
2. Shield persistence across reboot; who can clear it besides us.
3. `shield.webDomains` viability for the Safari leak.
4. Background audio behavior under a freshly-raised shield.
5. Exact iOS 26 build that fixed the device-passcode revocation bug.
6. Post-suspension traffic availability (exit-starvation reality check): with all
   non-allowlisted apps shielded, how quickly does the controller actually receive a
   flow?
