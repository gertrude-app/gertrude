# MacExplorer — seeded interleaving explorer for the Mac app ↔ filter protocol

Port of the iOS blocker's `RecordingExplorer` pattern (ledgers 6-7,
`docs/ios-conformance.md`) to the macOS app. Lives in
`swift/macapp/App/Tests/MacSimTests/MacExplorer.swift` (+ `MacExplorerTests.swift`),
runs on the `MacSim` harness (`VirtualMac` world, real `AppReducer` + real
`Filter` reducer as live sim processes).

Run: `just macapp-test --filter MacExplorerTests` from `swift/`.
Deeper hunts: `EXPLORE_SEEDS=80 EXPLORE_STEPS=45 just macapp-test --filter MacExplorerTests`.

## The core design difference from iOS

The iOS oracle is *stateless register math*: durable registers on a shared
container are ground truth, so the spec's `entered`/`rederived`/`isValid`
functions re-derive expected state fresh at every observation point.

**The Mac has no shared container** — app and filter state converge only
through connection-oriented XPC. So the Mac oracle is a **state machine
replayed over the observable message log**: only app→filter messages that
actually *reached* the filter's exported object (`VirtualMac.deliveredXpc`,
appended on successful `xpcSend`) update the oracle's model of the filter,
plus the VM-witnessed OS lifecycle rules:

- **M1** (respawn reloads disk): `filterBooted()` = memory reset to a
  projection of the durably-persisted state (keychains, downtime *window*);
  ephemeral state (app-liveness, suspensions, downtime *pause*) lost.
- **M3** (fail-open): filter process absent ⇒ every flow expected `.allow`.
- **M4** (verdict finality): connections stay usable regardless of later
  filter state until reboot (tracked as leak stats, not violations — it's an
  OS rule, not our bug).
- **M5** (single retained XPC connection, last-wins): intent that never
  arrived — a send that failed because the other user's app held the
  connection, or the provider was dead — must NOT move the oracle, exactly as
  it cannot move the real filter.

Verdict derivation re-implements `Decision+Early`/`Decision+Flow` semantics
for the explorer's restricted universe (Safari flows from uids ≥ 501,
exact-domain keys with unrestricted scope, no exemption/filtering-disabled/
always-blocked — future dimensions). Keychain→allowed-hosts is the oracle's
own re-derivation (NOT the production `KeychainIndex`), so a matching bug
can't hide in both places.

### The alive-boundary indeterminacy

The filter reaps a lapsed `macappsAliveUntil` entry only at its next 60s
heartbeat tick. So for up to one heartbeat interval after a lapse, the
entry's presence — and any verdict depending on it (AWOL fail-closed vs
rule/suspension evaluation) — is indeterminate. The oracle dual-evaluates
(entry present vs absent); if the verdicts agree it asserts, otherwise it
skips and counts (`indeterminateSkips`). A lapse older than one full interval
is provably reaped (`absent`).

## The alphabet (18 actions)

Flows (`browse`, `openConnection`, `useConnections`), `advanceTime` (5s–25min,
crossing app heartbeats at 1/5/20min and the filter's 60s heartbeat),
`grantSuspension` (websocket push → app → XPC), `resumeFilterEarly`,
`refreshRules` (menu bar → checkIn → `sendUserRules`), `setRules` (mutates the
scripted checkIn output; oracle updates only on *delivery*), `setDowntime`
(window opens 2 sim-minutes out, 30min long — relative to the pinned epoch so
seeds reproduce forever), `pauseDowntime`/`resumeDowntime`, `launchApp`/
`quitApp` per user, `killFilter`/`respawnFilter`/`crashRecoverFilter`,
`rebootDevice`, `settle`. Two macOS users (`child` uid 502, `buddy` uid 503)
fight over the single retained XPC connection, exercising the M5 last-wins
churn (each app's 5-minute heartbeat steals the slot back; the other user's
sends fail until their next steal — the model is coded but the multi-user
case is still an un-witnessed DEFERRED item, so findings in that region are
model-relative).

## Violation classes

- `S-mac-unexpected-allow` — oracle says drop (determinate), flow allowed.
- `L-mac-blocking-stuck` — oracle says allow (determinate), flow dropped
  (the trapdoor class).
- Convergence (`converge()`: +2h, reboot, both users log in, +90s):
  `C-mac-unexpected-allow` / `C-mac-blocking-stuck` (world must agree with
  oracle in the settled state), `C-mac-suspension-survived`,
  `C-mac-app-projection-stuck`, `C-mac-xpc-not-reestablished` (liveness of
  the app's 5-minute reconnect self-healing), `M4-connection-survived-reboot`.

Failing seeds print a full JSON report (seed, action script, stats, trace
tail); `MacExplorer.replay`/`.shrink` minimize scripts for regression
scenarios.

## Findings (2026-07-06, first session)

1. **REAL BUG (fixed): persisted downtime never reloaded on filter respawn.**
   `Persistent.State` durably saves `userDowntime` (windows), but
   `Filter.reduce(.loadedPersistentState(.some))` never restored it — so a
   provider crash/respawn (or reboot) during downtime silently lifted
   downtime until the app's next rules delivery (checkIn heartbeat, up to
   20 minutes; forever if the app is gone — though then AWOL fail-closed
   masks it). Found by oracle analysis while modeling M1's
   durable-vs-ephemeral split; witnessed by the named scenario
   `DowntimeScenarioTests.testDowntimeSurvivesFilterCrashRespawn` (failed
   pre-fix: github.com ALLOWED mid-downtime after respawn; passes post-fix).
   Fix: one line restoring `state.userDowntime` in `loadedPersistentState`.
   NOTE: the fuzz corpus (80 seeds × 45 steps) did NOT reach this — the
   sequence (downtime delivered → enter window → crash → 5-min reconnect +
   alive re-sent *without* rules re-delivery → browse allowed host, all
   inside the window) is too narrow for current weights. Witness-by-scenario
   + oracle-guarding-the-reload-path is the durable coverage.

2. **Production wart (fixed): filter→app effects threw unhandled.**
   `suspensionTimerEnded`/`staleSuspensionFound` (`notifyFilterSuspensionEnded`)
   and `flowBlocked` (`sendBlockedRequest`) threw out of `Effect.run` whenever
   the retained connection was down (dead app, dead connection) — benign
   runtime-warning noise in prod, surfaced as failures by the sim on its first
   corpus run. Made best-effort (`try?`), matching the existing `sendLogs`
   precedent and the design intent: filter→app messages only *accelerate*;
   the app independently clears its suspension projection at expiry via its
   own every-minute heartbeat.

3. **Observed semantic worth a product look: downtime outranks suspensions.**
   `Decision+Early` checks downtime before the suspension allow — a parent
   granting a filter suspension during the child's downtime window does NOT
   lift downtime (the app still shows/announces the suspension). The oracle
   mirrors the code, so no violation — but the app-side UX may mislead.
   (Pause-downtime is the intended lever; it's admin-gated in the menu bar.)

4. **Sim-enabling production seam: `FilterSuspension.isActive(at:)`.**
   `isActive` read raw `Date()` (the KNOWN SEAM from the spike); both filter
   call sites now pass the injected `self.now`. This let `VirtualMac` pin its
   clock to a fixed epoch (2025-01-01T00:00:00Z) — required for reproducible
   explorer seeds and deterministic time-of-day downtime windows.

## Corpus numbers (80 seeds × 45 steps, all green post-fix)

Non-vacuity is asserted in the default corpus test: suspension allows, AWOL
drops, fail-open allows, rule allows, and default drops all exercised.
Runtime ~6s/run (converge dominates: +2h advance = 120 heartbeat ticks × 2
apps); default corpus 12×30 ≈ 60s.

## Future dimensions

- exemption / filtering-disabled / always-blocked / schedules in the key
  universe (oracle + actions)
- app update/migration + sleep/wake actions (need VM witnesses first —
  honesty clause)
- weight tuning or a composite action to reach the downtime-respawn overlap
  organically
- multi-user XPC last-wins VM witness (deferred; would ground the M5 region)
