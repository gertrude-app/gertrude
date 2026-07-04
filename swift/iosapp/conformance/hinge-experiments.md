# Recording-Feature Hinge Experiments — Device Runbook

One tethered session (~45 min) answering the three load-bearing questions that gate the
screen-recording architecture exploration (see `docs/ios-recording-design.md`). All
measurement comes from device-side witness logs via `capture.sh collect` — no database
rows are written or read anywhere (the `ScreenshotUploadUrl` resolver on this branch
returns a presigned S3 URL and touches no tables).

## The three hinges

| #   | Question                                                                                                                                                | Gates                                                                                                 | Instrumentation                                                                                                                |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 1   | How stale can the recorder's `screenshotLastSaved` write be when the filter reads it at flow-decision time?                                             | The liveness-window safety core of **every** design variant (6s window = 5s cadence + 1s wiggle)      | `recorder-liveness-bump` (write side, actual ts written) vs `filter-liveness-check` (read side, value seen + elapsed)          |
| 2   | Does the background-URLSession chain sustain uploads at ~5s frame cadence while the app is suspended?                                                   | App-owned uploads as the **primary** evidence path (current implementation)                           | `app-upload-enqueued` / `app-upload-completed` (incl. `stranded=`) / `app-bg-session-wake` / `screenshot-drain` backlog series |
| 3   | Can the controller upload evidence every ~5s when the filter summons it via `needRules` during a suspension, within NE memory limits, without crashing? | The untried possibly-simplest design: fully level-triggered, controller-owned evidence, app = UX only | `filter-summoned-controller` / `controller-spike-upload` (duration, `os_proc_available_memory` headroom)                       |

All three run concurrently in one recording session; the hinge-3 spike uploads a synthetic
150KB payload (never touches the real screenshot files), so it cannot contaminate the
hinge-2 measurement.

## Spike code (temporary, `#if DEBUG && os(iOS)` — invisible to sim + release)

- `LibFilter/FilterProxy.swift` — while a suspension is valid, every ≥5s one flow verdicts
  `.needRules` instead of `.allow` (the summon)
- `LibController/ControllerProxy.swift` — flows arriving while a suspension is live
  (re-derived from disk) are allowed + trigger `spikeUploadEvidence()`
- These are experiment scaffolding, not part of the R-rule conformance contract; rip out
  or productionize after the data is in.

## Prerequisites

1. This branch (`bl-screen-recording`) built to the phone from Xcode — app, filter,
   controller, AND recorder targets all from the same build (a stale controller would drop
   flows the filter summons during suspension).
2. Local API running **from this branch** (`just watch-api`) + ngrok tunnel matching
   `iosapp/config/Local.xcconfig`.
3. Phone onboarded + connected to a Gertrude account (already done: UDID
   `00008150-000148983AB8401C`).

## Session script

1. **Sanity (2 min):** app foreground, browse a blocked site in Safari → blocked.
2. **Request + grant:** in app, request a suspension (any duration). Grant it manually,
   forcing a 30-min window so expiration can't end the experiment early (the app anchors
   `expiration = broadcastStart + duration` from this row's value):

   ```sql
   update blocker_app.suspend_filter_requests set status = 'accepted', duration = 1800 where status = 'pending';
   ```

3. **Start recording** with the app FOREGROUND (tap start-recording in app, confirm in the
   system broadcast picker). Verify blocked site now loads.
4. **Background the app immediately** (home screen) — suspended-app is the steady state
   under test. Do NOT reopen the app until step 7.
5. **Use the phone normally for ~10 min** (see "How long" below): browse in Safari (mix
   blocked + normal sites — traffic is what drives filter checks and summons), keep the
   screen changing (drives real frame saves), include a 1–2 min static-screen pause
   (drives `kind=unchanged` bumps). Browsing need not be continuous — gaps produce no
   data points but corrupt nothing.
6. **Stop the recording from Control Center** (NOT from the app) — exercises tombstone +
   darwin-finish while the app is suspended. Verify blocked site is re-blocked within
   ~10s.
7. **Wait 2 min, then reopen the app** — coalesced darwin delivery + foreground drain of
   any backlog.
8. **Capture + analyze:**

   ```sh
   cd swift/iosapp/conformance
   ./capture.sh collect 00008150-000148983AB8401C 1h
   node check.mjs logs/witnesses-<ts>.ndjson --hinges
   ```

   Must be `collect` — app-process witnesses (all of hinge 2) never appear in `stream`
   (known blind spot, see docs/ios-conformance.md).

## How long does the session need to be?

~10 minutes settles hinges 1 and 3: propagation lag is per-write behavior (~120 writes,
hundreds of reads in 10 min), and summon cadence / upload success / memory headroom show
their shape within minutes. Only hinge 2 is time-dependent — iOS's treatment of a
backgrounded app changes over the first several minutes (background-execution grace, then
progressively more wake coalescing as the system notices the pattern), so a short session
measures the honeymoon period. Asymmetry: a hinge-2 FAIL at 10 min is conclusive; a PASS
at 10 min is provisional until a longer window confirms it.

Sessions compose: the analyzer handles multiple recording windows and `collect` is
retroactive (nothing needs to be tethered or attended during recording), so several
casual ~10-min recordings across a normal day + one `collect` pull at the end beat one
long sit — they sample different system states. Do the focused 10-min pass first;
extend hinge 2's evidence lazily afterward.

## Reading the results

**Hinge 1 — PASS:** stale reads ≈ 0, false-invalid = 0, `elapsedMs` max < 6500 while
recording. **FAIL:** any false-invalid (filter would flap mid-recording → widen window or
switch liveness medium to file mtime); systematic read-staleness above 1.5s (cfprefsd
propagation lag → same remedies).

**Hinge 2 — PASS:** uploads track saves (bounded backlog), inter-upload gaps < 60s
throughout the window, `bg-session wakes > 0`, stranded completions being processed.
**FAIL:** multi-minute gaps / backlog growing until app reopen → app uploads demote to
backstop; primary evidence path must live elsewhere (hinge 3).

**Hinge 3 — PASS:** summon gaps ≈ 5s while browsing, spike ok-rate ≈ 100%, mem headroom
min > 5MB, controller re-inits during recording = 0. **FAIL:** controller crashes/re-inits
or memory floor near zero → controller-as-uploader is out; upload failures with
`noAccountConnection` → check connection storage.

Record findings (numbers, not just verdicts) in `docs/ios-recording-design.md`'s
device-testing section when done.

## Postscript — experiment completed 2026-07-04

All three hinges answered in one 28.6-min session (results in
`docs/ios-recording-design.md` §Device findings; protocol consequences in
`docs/ios-recording-protocol.md`). The spike scaffolding described above was then
PRODUCTIONIZED, so this runbook is historical: the filter's summon and the
controller's allow-while-recording are now ungated production behavior, the
controller drains *real* screenshots via `uploadScreenshotDirect` (the
`controller-spike-upload` witness is gone — look for `screenshot-drain` /
`screenshot-drain-done` from the controller process instead), and `check.mjs
--hinges`'s hinge-3 section only fully applies to captures from spike-era builds.
The hinge-1 (liveness) and hinge-2 (app upload chain) sections remain valid for
any capture.
