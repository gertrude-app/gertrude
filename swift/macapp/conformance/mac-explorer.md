# MacExplorer - seeded interleaving explorer for the Mac app/filter protocol

MacExplorer drives the real app and filter reducers inside `VirtualMac`, then checks every
observed flow verdict against an independent oracle replayed from delivered app-to-filter
messages. Runs are seeded and deterministic: any failing seed reproduces forever and can
be shrunk into a named regression scenario.

Run: `just macapp-test --filter MacExplorerTests` from `swift/`. Deeper hunts:
`EXPLORE_SEEDS=80 EXPLORE_STEPS=45 just macapp-test --filter MacExplorerTests`.

## Scope

MacSim verifies the filter's flow-verdict path and app/filter protocol convergence: XPC
lifecycle and per-user routing, persistence across provider crash and reboot, liveness
windows, suspensions, and downtime. A green MacSim run is **not** whole-app verification.

Planned expansion, in priority order (each addition follows `maintenance-contract.md`:
modeled rule, evidence, checker, and doc row in the same PR):

- exemption / filtering-disabled / always-blocked / schedules in the key universe
  (oracle + actions) — these sit inside the verdict path, so their absence is the
  main limit on what a passing oracle proves
- app update/migration + sleep/wake actions (need VM witnesses before modeling)
- weight tuning or a composite action to reach the downtime-respawn overlap organically
- broader browser/socket flow-delivery distinctions (need VM evidence first)

Out of scope with no plan to model — these have little interplay with the multi-process
protocol behavior the sim exists to check, and are better served by unit tests:
screenshot monitoring, keystroke logging, app blocking, onboarding, menu bar and webview
UI, health-check repairs beyond XPC reconnect, and the websocket command surface beyond
suspension grants and rule refreshes.

## Design

The Mac app and filter do not share a durable container. State converges through
connection-oriented XPC, so the oracle is a state machine over the observable message log:

- Only messages appended to `VirtualMac.deliveredXpc` update the oracle.
- Failed app-to-filter intent must not update the oracle.
- Provider relaunch reloads durable state and loses in-memory state.
- Already-allowed connections remain usable until reboot.
- Per-user XPC connections route app/filter messages by uid; logs go to the most recently
  attached app connection.

Verdict derivation re-implements the relevant `Decision+Early` and `Decision+Flow`
behavior for the explorer's small universe: Safari/WebKit flows from non-system uids,
exact-domain keys, no exemption/filtering-disabled/ always-blocked dimensions yet.
Keychain-to-host matching is intentionally not delegated to production `KeychainIndex`.

## Drift Control

Code comments use `sync:<id>` markers where the simulator directly mirrors a production
implementation. When changing either side of a marked pair, run `rg "sync:<id>"` and audit
the other side in the same PR. The inline comment should include only the id and a short
behavior label, not file or function names.

The full maintenance contract is in `maintenance-contract.md`.

OS behavior that is not production Swift code is tracked separately in
`vm-witness-findings.md`.

### Alive-boundary indeterminacy

The filter reaps a lapsed `macappsAliveUntil` entry only at its next 60s heartbeat tick.
So for up to one heartbeat interval after a lapse, the entry's presence, and any verdict
depending on it (AWOL fail-closed vs rule/suspension evaluation), is indeterminate. The
oracle dual-evaluates (entry present vs absent); if the verdicts agree it asserts,
otherwise it skips and counts (`indeterminateSkips`). A lapse older than one full interval
is provably reaped (`absent`).

## Alphabet

Flows (`browse`, `openConnection`, `useConnections`), `advanceTime` (5s-25min, crossing
app heartbeats at 1/5/20min and the filter's 60s heartbeat), `grantSuspension` (websocket
push -> app -> XPC), `resumeFilterEarly`, `refreshRules` (menu bar -> checkIn ->
`sendUserRules`), `setRules` (mutates the scripted checkIn output; oracle updates only on
_delivery_), `setDowntime` (window opens 2 sim-minutes out, 30min long, relative to the
pinned epoch so seeds reproduce forever), `pauseDowntime`/`resumeDowntime`, `launchApp`/
`quitApp` per user, `killFilter`/`respawnFilter`/`crashRecoverFilter`, `rebootDevice`,
`settle`. Two macOS users (`child` uid 502, `buddy` uid 503) exercise the M5 per-user
connection map: each app has an independent channel, same-user reconnects replace only
that user's entry, app exit removes only that user's entry, and provider/listener loss
clears the map.

## Violation classes

- `S-mac-unexpected-allow`: oracle says drop (determinate), flow allowed.
- `L-mac-blocking-stuck`: oracle says allow (determinate), flow dropped (the trapdoor
  class).
- Convergence (`converge()`: +2h, reboot, both users log in, +90s):
  `C-mac-unexpected-allow` / `C-mac-blocking-stuck` (world must agree with oracle in the
  settled state), `C-mac-suspension-survived`, `C-mac-app-projection-stuck`,
  `C-mac-xpc-not-reestablished` (liveness of the app's 5-minute reconnect self-healing),
  `M4-connection-survived-reboot`.

Failing seeds print a full JSON report (seed, action script, stats, trace tail);
`MacExplorer.replay`/`.shrink` minimize scripts for regression scenarios.

## Sabotage Validation

Temporary production-code mutations were applied and reverted to check that the harness is
non-vacuous in the main modeled regions:

| ID  | Seeded bug                                             | Caught by                                                      |
| --- | ------------------------------------------------------ | -------------------------------------------------------------- |
| S1  | Dropped persisted downtime reload on provider relaunch | `DowntimeScenarioTests.testDowntimeSurvivesFilterCrashRespawn` |
| S2  | Made app liveness recording a no-op                    | `ProviderCrashScenarioTests` liveness/relaunch cases           |
| S3  | Removed AWOL fail-closed from flow decisions           | `ProviderCrashScenarioTests` liveness/relaunch cases           |
| S4  | Let filter-to-app XPC failures throw out of effects    | `FilterReducerTests.testFilterToAppMessagesAreBestEffort`      |

S1-S3 exercise MacSim scenarios/oracle against real filter behavior. S4 is reducer-level
coverage for a bug class first exposed by MacSim, but it is not an oracle comparison.

## Corpus Numbers

Non-vacuity is asserted in the default corpus test: suspension allows, AWOL drops,
fail-open allows, rule allows, and default drops all exercised. Runtime ~6s/run (converge
dominates: +2h advance = 120 heartbeat ticks x 2 apps); default corpus 12x30 is about 60s.

## CI Tiers

- Per PR: `just macsim-test` runs the named scenarios, default explorer corpus,
  determinism check, and non-vacuity counters.
- Nightly/manual: `just macsim-hunt` runs `MacExplorerTests` with `EXPLORE_SEEDS=80` and
  `EXPLORE_STEPS=45`.
- Regression seeds: shrink a failing action script and commit it as a named scenario.
  Treat `MacSeededRNG` output as stable; changing it invalidates historical seed
  references.
