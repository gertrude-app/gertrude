# iOS Blocker OS-Model Conformance

The simulation harness (`swift/iosapp/lib-ios/Sources/LibSim/`) tests the blocker's
app/controller/filter interactions against a **model of iOS**, not iOS itself. Every
modeled behavior is an `OS RULE Rn` doc comment in `VirtualDevice.swift`. This workflow
validates those rules against a real device: DEBUG builds emit `[G•] WITNESS <event>`
os_log lines (`LibCore/Conformance.swift`, compiled out of release builds) at the
lifecycle and handoff points the rules make claims about; tooling captures them from a
tethered device and mechanically checks each rule.

Run a campaign when: an OS RULE is added or changed, a new iOS major ships, or the sim
and observed device behavior disagree.

## The rules and how to provoke them

| Rule | Claim | Witnesses | Provocation |
| --- | --- | --- | --- |
| R1 | filter proxy init → `startFilter` adjacent, same process | `filter-proxy-init` → `filter-start` | reboot; or kill filter via Settings toggle |
| R2 | controller init → `startFilter` adjacent | `controller-proxy-init` → `controller-start` | reboot |
| R2 (migration race) | migration is idempotent; app and controller both attempt it, whichever launches first wins | `app-migrated` XOR `controller-migrated` per update (never both within 5min) | update the app, then launch the app before opening Settings — and again the other order |
| R3 | `.needRules` verdict re-delivers flow to controller | `filter-need-rules` → `controller-received-flow` | browse ~50+ requests (DEBUG freq) |
| R4 | `withUpdateRules: true` triggers filter `handleRulesChanged` | `controller-verdict update=true` → `filter-rules-changed` | change rules in dashboard, then browse |
| R5 | `notifyRulesChanged()` reaches filter iff filter running | `controller-notified-rules-changed` → `filter-rules-changed` | same as R4 (informational: misses expected if filter dead) |
| R6 | reboot relaunches both providers, order indeterminate | launch-sequence timeline | reboot several times, compare orders |
| R7 | app sentinel requests arrive as filter flows | `app-sentinel-sent` → `filter-sentinel` | open info sheet / trigger rule refresh in app |
| R8 | successful install starts both providers | `app-installed-filter` → both `*-proxy-init` | fresh onboarding install |
| R9 | processes die anytime; only app-group storage survives | `filter-stop` / `controller-stop` → later `*-proxy-init` (new pid); informational — a stop with no later init is expected for the session's last stop | memory pressure (many Safari tabs / camera), observe re-inits |
| R10 | broadcast picker launches recorder; suspend sentinel arrives as a flow; screenshots follow suspension; stopping recording resumes filter on next flow; ~50MB memory cap; never auto-relaunched | `recorder-start` → `filter-sentinel suspend-filter`; `filter-suspended` → `recorder-screenshot-saved`; `recorder-stop` → `filter-resumed` | request + grant suspension from dashboard, start recording in app, browse, stop recording, browse again |
| R11 | darwin notifications delivered promptly to running observers; suspended app gets one coalesced delivery on resume; nothing queued for dead processes | `recorder-start` → `app-received-recorder-event` (informational) | start/stop recording with app foregrounded, then again after force-quitting the app |

## Capturing

Device must run a **DEBUG build** (witnesses compile out of release). Two modes, both in
`swift/iosapp/conformance/`:

```bash
# live stream while you provoke rules (idevicesyslog, per ios-block-rule-analysis.md).
# TWO limitations, both proven on-device 2026-07-03:
#  1. stream DROPS its connection during a reboot and doesn't reconnect before the
#     extensions finish their near-instant init/start sequence, so R1/R2/R6's
#     init-time witnesses are reliably missed — use `collect` for reboot-adjacent rules.
#  2. stream NEVER surfaces host-app process lines — proven by overlap: the unfiltered
#     probe capture (13:40:52-13:41:21) contains zero app-process lines while the
#     collect archive shows app[636] emitting app-sentinel-sent at 13:41:15.843 inside
#     that window (and the probe itself caught the filter RECEIVING those sentinels).
#     (An earlier session's "0 app-sentinel-sent" also had a second sufficient cause —
#     a wrong-branch build lacking the witness — but the blind spot stands on its own.)
#     App-side witnesses (R7 send side, R8, migration race) REQUIRE `collect`; `stream`
#     is fine for steady-state extension-side provocations (R3/R4/R5 and the filter
#     side of R7).
./capture.sh stream

# retroactive: pull the device log archive (default level persists across reboots,
# but rotates within hours-to-days — collect promptly after the session)
./capture.sh collect <udid> 2h
```

## Checking

```bash
node check.mjs logs/witnesses-<ts>.log        # or .ndjson
node check.mjs logs/witnesses-<ts>.log --timeline
```

Per rule: `CONFIRMED xN`, `VIOLATED` (with timestamps), `UNEXERCISED`, or — for R5 and R9,
where a miss is sometimes expected rather than a bug — `INFO N followed, M not`. Treat
`UNEXERCISED` as seriously as violations — it means the campaign never provoked the rule
and the model still has zero evidence for it. For the `INFO` rules, a handful of misses is
normal (filter dead when notified; session's last stop never relaunching); a large or
growing count of misses across a multi-day capture is not, and is worth digging into. The
pairing windows in `check.mjs` are model parameters, not facts; if a real capture shows
e.g. init→start legitimately taking longer than the window, loosen the window *and* record
what was observed below. The R2 migration race isn't a pairing check (both sides firing
for the *same update*, not one missing the other, is the bug) — `check.mjs` reports it
separately as `CONFIRMED`/`VIOLATED`/`UNEXERCISED` right after the per-rule table. Only
app/controller migrations within 5 minutes of each other count as a violation: a capture
spanning multiple update provocations (the table above says to run both orders) or a
delete+reinstall legitimately contains migrations from both sides, far apart.

## Verification record

| Rule | Last verified | iOS version | Notes |
| --- | --- | --- | --- |
| R1 | 2026-07-03 | — | init→start confirmed x4 (collect, 40-min session w/ 4 reboots); all 4 show both-inits-then-both-starts pattern (filter-init → controller-init → filter-start → controller-start), validating the sim's split-init model |
| R2 | 2026-07-03 | — | init→start confirmed x4 (collect); migration race UNEXERCISED — needs a real old→new app update, not forceable |
| R3 | 2026-07-03 | — | needRules→flow confirmed x72, VIOLATED x1 (collect): a 35ms burst of 4 needRules verdicts was coalesced into 1 controller delivery by the OS — known sim simplification (1:1 model correct for steady state; burst coalescing not modeled) |
| R4 | 2026-07-03 | — | withUpdateRules→filter confirmed x2 (collect, driven by real dashboard rule changes via sentinel) |
| R5 | 2026-07-03 | — | notifyRulesChanged→filter confirmed x3 (collect) |
| R6 | 2026-07-03 | — | 4 reboot launches observed: filter-init ALWAYS preceded controller-init (160-574ms), 6-for-6 filter-first across all campaigns; "order indeterminate" claim unverified — may be deterministically filter-first. Both orders still tested conservatively |
| R7 | 2026-07-03 | — | CONFIRMED x6 (collect): `app-sentinel-sent` → `filter-sentinel` pairing fully confirmed with clean main-branch build. Earlier "0 app-sentinel-sent" had two independent sufficient causes: a wrong-branch build (screen-recording branch, lacks the witness) AND the idevicesyslog app-process blind spot (see Capturing). Observed fan-out: each single send produced 6-8 `filter-sentinel` deliveries (one HTTPS request → multiple flows); sim models 1:1 — documented simplification |
| R8 | 2026-07-03 | — | install→both providers confirmed x1 (collect, onboarding); both-inits-then-both-starts pattern confirmed |
| R9 | 2026-07-03 | — | zero filter-stop/controller-stop witnesses across 4 reboots — reboots kill extensions outright without stopFilter callback (validates "can die without notice" caveat). Relaunch-after-death half UNEXERCISED — needs deliberate memory pressure (weekend soak) |
| R10 | never | — | drafted 2026-07-02 from RPBroadcastSampleHandler docs + observations from the 2025 recording experiment (`bak-swift` branch `chris`); no campaign run yet |
| R11 | never | — | drafted 2026-07-03 from notify(3) semantics + the Apr 2025 darwin xpc prototype (`bak-swift` branch `ios-test-rewrite`); key open question: real coalesced-on-resume latency for a suspended app |

## Maintenance

Adding a model behavior = four artifacts, same PR: the `OS RULE Rn` doc comment in
`VirtualDevice.swift`, witness emission(s) in the production seam, a rule entry in
`check.mjs`, and a row in the tables here.
