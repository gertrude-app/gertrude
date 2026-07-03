# iOS Screen-Recording Filter Suspension — Design Notes

The blocker's recording-backed filter suspension (child requests a pause, parent grants,
blocking lifts only while the screen is being recorded and screenshots flow to the
parent) was prototyped twice in spring 2025 with two materially different architectures,
then backed out entirely. This documents the semantic difference between the two, what
each got right, and the direction chosen for the resurrection — so the choice survives
the git history of a deleted feature.

## History

- **Apr 2025 (Jared, `bak-swift` branches `ios-test-rewrite` / `ios-v1-5-x`):**
  app-orchestrated model. Introduced the `.suspended` protection mode, suspend/resume
  sentinels, the expiration key, and darwin-notification events between recorder and
  app.
- **May 2025 (Chris, `bak-swift` branch `chris`, tip `0cd8720b`):** reworked to a
  recorder-orchestrated model in `23c08e81`..`07128042`: deleted the darwin events and
  app orchestration, moved uploads into the recorder extension, added filter-side
  screenshot liveness. Collaboration ended shortly after; the tip carries unresolved
  TODOs.
- **Jul 2026:** resurrected on the simulation harness. First landed as the chris-era
  model (most recent prior art), then moved to the app-orchestrated model per this doc.

## The two models

|                       | App-orchestrated (Jared)                                        | Recorder-orchestrated (Chris)                          |
| --------------------- | --------------------------------------------------------------- | ------------------------------------------------------ |
| Coordination          | Edge-triggered: recorder posts darwin events, app reacts         | Level-triggered: no messages; filter re-derives truth from disk timestamps at each flow decision |
| Suspension authority  | App state machine (grant + observed broadcast start)             | Recorder unilaterally suspends on broadcast start       |
| Expiration            | `broadcastStart + grantedDuration`, written by app               | Hardcoded 24h from recorder (TODO'd), filter liveness as the real bound |
| Uploads               | App drains files the recorder drops in the shared container      | Recorder uploads on a timer inside the extension        |
| Liveness enforcement  | App watchdog timer (frozen when app suspended)                   | Filter checks `screenshotLastSaved` at flow-decision time |
| Recorder complexity   | Dumb: save frames, bump liveness, emit events                    | Image pipeline + URLSession + retry + final-drain gymnastics |

## What each got right / wrong

**Recorder-orchestrated problems (visible in the chris commit record):** the broadcast
extension runs under a ~50MB memory cap the CoreImage pipeline already strains — adding
networking raises crash risk, and a recorder crash kills the broadcast *and therefore
the suspension*. Moving uploads into a process that dies abruptly self-inflicted the
"upload remaining once recording stops" edge case and the cancellation/detached-task
gymnastics around process death. Losing the events left the app UI unable to know when
recording actually started ("TODO: need to hook into start of broadcast, not tap") and
forced the 24h expiration hack.

**Recorder-orchestrated insight worth keeping:** level-triggered enforcement in the
filter is strictly more robust than any watchdog living in a process that can be
suspended or killed — the filter is always consulted at the exact moment that matters
(a flow trying to pass), and deriving "is recording demonstrably live?" from disk state
survives every process-death and reboot scenario (see the LibSim recording scenarios).

**App-orchestrated problems (as written in Apr 2025):** uploads used `URLSession.shared`
with no background handling, so once iOS suspends the backgrounded app (seconds after
the child switches away to actually use the recorded device), uploads stall until the
app next gets CPU. The app-side liveness watchdog freezes for the same reason. Darwin
notifications are not delivered to a suspended process in real time (they coalesce and
arrive on resume), so `broadcastFinished → resume` can be observed late.

**App-orchestrated insights worth keeping:** single authority for the suspension state
machine; expiration anchored at actual broadcast start with the real granted duration;
a minimal recorder that cannot crash the broadcast doing side work; typed events as a
mockable seam; instant UI truth and instant resume *when the app is awake*.

## Chosen direction: events for responsiveness, state for correctness

The resurrection uses Jared's topology with the one piece of Chris's rework that was a
genuine improvement kept as the safety floor:

- Recorder is dumb: saves changed frames, bumps `screenshotLastSaved` every processed
  frame, emits darwin events, and back-dates the liveness timestamp on graceful stop (a
  "tombstone", from the `recordingDemo` branch) so the filter resumes promptly even if
  nobody hears the stop event.
- App owns the state machine: parent grant stores the duration; on the darwin
  `broadcastStarted` it writes `expiration = now + grantedDuration` and fires the
  suspend sentinel; on `broadcastFinished` (or user tap) it clears the key, fires the
  resume sentinel, and drains uploads.
- App owns uploads, as **bounded drains on wake points** (broadcast events, app
  foregrounding, later: background-session wakes) — not a resident timer, which the
  platform would freeze anyway.
- Filter keeps level-triggered enforcement as the fail-safe: suspension is valid only
  while `expiration` is in the future *and* screenshots are provably fresh (6s window),
  re-derived from disk on every flow decision and on filter relaunch. Every dropped
  edge — missed darwin event, killed process, reboot — degrades to "blocking resumes
  within seconds."

## Upload wake vectors — to verify on device

The open question is evidence latency: how stale can screenshots get while the child
records with the app suspended? Mechanisms to test, roughly in order of promise:

1. **Background `URLSession`** (`URLSessionConfiguration.background`): transfers run in
   `nsurlsessiond` while the app is suspended; completion wakes the app via
   `handleEventsForBackgroundURLSession`, giving it CPU to enqueue newly-dropped files —
   a self-sustaining chain. Caveats: wake-ups coalesce and are somewhat discretionary;
   uploads must be from-file (they are). This is the primary candidate.
2. **Silent push** (`content-available`): the API knows the moment a suspension is
   granted and could wake the app as the session starts. Throttled by the system;
   supplementary only.
3. **`BGTaskScheduler`**: `BGAppRefreshTask` grants ~30s opportunistically, scheduled
   from the child's app-usage patterns (rarely-opened parental-control app → rare
   grants); `BGProcessingTask` gives minutes but typically requires idle/charging.
   Neither is timely enough for live evidence; both are fine as backlog cleanup.
4. **Controller drain** (implemented): the control provider uploads leftover files
   during rule refreshes whenever recording is not live — the backstop when the app
   never wakes.
5. **Darwin coalesced delivery on resume** (free): any wake for whatever reason
   delivers the pending event and triggers a drain.

Device-testing checklist: how long after backgrounding does the app actually suspend;
whether the background-session chain sustains ~5s-cadence file drops; real darwin
delivery latency to a suspended app across start/stop; whether `broadcastFinished` even
runs when the recorder is memory-killed; BGAppRefreshTask grant frequency on a
child-usage-profile device.
