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
| R3 | `.needRules` verdict re-delivers flow to controller | `filter-need-rules` → `controller-received-flow` | browse ~50+ requests (DEBUG freq) |
| R4 | `withUpdateRules: true` triggers filter `handleRulesChanged` | `controller-verdict update=true` → `filter-rules-changed` | change rules in dashboard, then browse |
| R5 | `notifyRulesChanged()` reaches filter iff filter running | `controller-notified-rules-changed` → `filter-rules-changed` | same as R4 (informational: misses expected if filter dead) |
| R6 | reboot relaunches both providers, order indeterminate | launch-sequence timeline | reboot several times, compare orders |
| R7 | app sentinel requests arrive as filter flows | `filter-sentinel` | open info sheet / trigger rule refresh in app |
| R8 | successful install starts both providers | `app-installed-filter` → both `*-proxy-init` | fresh onboarding install |
| R9 | processes die anytime; only app-group storage survives | `filter-stop` / `controller-stop`, gaps + new pids | memory pressure (many Safari tabs / camera), observe re-inits |

## Capturing

Device must run a **DEBUG build** (witnesses compile out of release). Two modes, both in
`swift/iosapp/conformance/`:

```bash
# live stream while you provoke rules (idevicesyslog, per ios-block-rule-analysis.md);
# survives device reboot — leave it running and reboot the phone for R1/R2/R6
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

Per rule: `CONFIRMED xN`, `VIOLATED` (with timestamps), or `UNEXERCISED`. Treat
`UNEXERCISED` as seriously as violations — it means the campaign never provoked the rule
and the model still has zero evidence for it. The pairing windows in `check.mjs` are
model parameters, not facts; if a real capture shows e.g. init→start legitimately taking
longer than the window, loosen the window *and* record what was observed below.

## Verification record

| Rule | Last verified | iOS version | Notes |
| --- | --- | --- | --- |
| R1–R9 | never | — | rules drafted 2026-07-02 from Apple docs, code comments, and prior on-device logging; no dedicated campaign run yet |

## Maintenance

Adding a model behavior = four artifacts, same PR: the `OS RULE Rn` doc comment in
`VirtualDevice.swift`, witness emission(s) in the production seam, a rule entry in
`check.mjs`, and a row in the tables here.
