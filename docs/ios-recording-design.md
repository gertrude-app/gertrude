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

## Device findings — hinge experiments, 2026-07-04

One 28.6-min recording session (iPhone, iOS 18, DEBUG build, app backgrounded ~15s in,
stopped from Control Center; capture `witnesses-20260704-121535.ndjson`, analysis
`check.mjs --hinges`; instrumentation + method in `conformance/hinge-experiments.md`).
Three questions were posed; all three answered decisively.

**1. Liveness propagation (recorder write → filter read): PASS, exactly zero staleness.**
325 recorder bumps, 215 filter flow-decision reads; in every single read the filter saw
the freshest value the recorder had written (read-staleness p50/p99/max = 0ms). Shared
`UserDefaults` via cfprefsd is effectively instantaneous cross-process. The 6s liveness
window (5s cadence + 1s wiggle) is sound as a staleness bound; no widening needed.

**2. App bg-URLSession upload chain: FAIL as primary evidence path.** 292 frames saved
during the recording; the suspended app uploaded essentially none of them (2 bg-session
wakes in the whole session, both *after* recording ended; max inter-upload gap 1733s ≈
the entire recording). Backlog hit 291 files, drained only to 269 on app reopen (a 500
from the API broke the drain loop, retries at +6 and +16 min each moved it barely).
Evidence latency under app-owned uploads is unbounded — "whenever the app is next
opened." The chain is a backstop, not a primary.

**3. Controller-as-uploader (filter summons via needRules): PASS on every axis.** 26/26
spike uploads succeeded end-to-end (presigned-URL fetch + 150KB PUT from inside the
control provider), median 378ms, memory headroom flat at 44-45MB across the session (no
leak; the NE budget is far larger than the assumed ~15MB), zero controller crashes.
This is the primary evidence path going forward.

**4. (Unplanned) The one-way suspension trapdoor — the session's biggest finding.** At
4.5 min in, an 18s gap in liveness bumps (screen off/locked pauses ReplayKit buffer
delivery entirely) coincided with a background flow: the filter's level-triggered check
correctly saw stale evidence and ended the suspension — but nothing ever re-entered it.
The kid spent the remaining 24 minutes recording *and blocked*, because suspension entry
is edge-triggered (sentinel at broadcast start) while exit is level-triggered, and
`rederived` runs only at filter relaunch. Meanwhile the controller — which re-derives
suspension from disk on every flow it happens to receive — recovered automatically after
every gap and kept uploading until 11:53. The asymmetry is the bug: entry must be
level-triggered too (re-derive on flow decisions while the expiration key is live), with
the sentinel kept only as the fast edge. Two more >10s bump gaps later in the session
would have re-tripped the same trapdoor. This also retroactively resolves the "is
re-suspension after filter relaunch intended?" question: yes — it is *required*.

Consequences: upload vectors 1/2/3/5 above demote to backlog cleanup; vector 4 inverts
from backstop to primary (summoned during recording, not just when recording is dead).
Protocol spec capturing all of this: `docs/ios-recording-protocol.md`.
