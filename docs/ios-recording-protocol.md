# iOS Recording Suspension — Protocol Specification

The recording-backed filter suspension as a four-process distributed protocol. This is
the normative reference the LibSim scenarios and (future) interleaving explorer check
against; `docs/ios-recording-design.md` holds the history and device evidence behind
each decision. Pattern name used throughout the codebase: **durable-state
reconciliation with edge-triggered hints** — durable facts on shared disk each with a
single writer, derivation rules applied by each process at its own decision points, and
best-effort events that only accelerate convergence, never carry authority.

Device evidence citations refer to the 2026-07-04 hinge session and the same-day
lock/static validation session (design doc §Device findings, both sections).

## Processes

| Process    | Lifecycle                                                                       | Powers                                                 |
| ---------- | ------------------------------------------------------------------------------- | ------------------------------------------------------ |
| app        | user-launched only; suspended seconds after backgrounding; killable             | UI, API, darwin RX, sentinel TX, group-disk read/write |
| filter     | OS-launched; on-demand relaunch on flow; killable; **consulted on every flow**  | flow verdicts; group-disk READ ONLY (write-clone quirk) |
| controller | OS-launched; relaunched with filter; killable; receives flows filter delegates  | network, API, group-disk read/write, ManagedSettings   |
| recorder   | user-initiated broadcast only; ~50MB cap; never OS-relaunched; dies on reboot   | frame pipeline, group-disk read/write, darwin TX        |

Scheduling reality (device-verified): once the app is backgrounded it gets no CPU —
darwin events coalesce until resume, timers freeze, bg-URLSession wakes are rare and
discretionary (2 wakes / 28 min). The filter and controller are the only processes
reliably given CPU during a recording, precisely because the child is generating
traffic.

## Shared registers (group container)

| Register               | Writer (sole)                | Readers            | Semantics                                                                 |
| ---------------------- | ---------------------------- | ------------------ | ------------------------------------------------------------------------- |
| `suspensionExpiration` | app                          | filter, controller | grant is live until this instant; written as `broadcastStart + duration` on darwin start; cleared by app on finish/early-end; **lingers if app dies — by design** (see D3) |
| `screenshotLastSaved`  | recorder                     | filter, controller | liveness heartbeat, bumped per processed frame (≤`heartbeatInterval` while screen on) whether or not a screenshot was saved; back-dated by `livenessWindow` on graceful stop (tombstone) |
| screenshot files + meta| recorder (create), drainers (delete on upload) | app, controller | the evidence itself; filename is the dedup key |

Register reads are effectively instantaneous cross-process (hinge 1: 0ms staleness over
215 reads). Nothing else about the protocol may assume faster than ~1s propagation.

## Channels (all best-effort; none carry authority)

| Channel                        | Guarantee                                                                     | Role |
| ------------------------------ | ----------------------------------------------------------------------------- | ---- |
| darwin events (recorder → app) | delivered iff app running & not suspended; coalesced on resume; else dropped  | UX truth + expiration anchor; loss degrades to slower entry, never wrong state |
| sentinels (app → filter, HTTPS magic hostnames) | delivered iff filter installed; **fans out 1 send → ~5-8 flow deliveries** (device-verified), so handling must be idempotent | fast edge for suspend/resume |
| needRules (filter → controller) | 1:1 per verdict (R3/R4-verified; rare OS burst-coalescing)                    | the filter's power to **summon** the controller — grant it CPU at will |
| API (app/controller ↔ server)  | ordinary network                                                              | grants, presigned upload URLs |

## State derivation rules

The single source of truth for "is the suspension live?" is a pure function of the
registers and the clock:

```
live(now) = suspensionExpiration != nil
         && suspensionExpiration > now
         && now - screenshotLastSaved ∈ [0, livenessWindow)   // 6s = heartbeat 5s + 1s wiggle
```

**Two cadences, deliberately decoupled (D6).** The `heartbeatInterval` (5s) is a
protocol constant: it drives the liveness bump, the `livenessWindow`, the summon
cadence, and therefore every fail-safe and recovery latency. The `screenshotInterval`
(evidence density — how often a changed frame is actually saved and uploaded) is
policy, parent-configurable per grant, defaulting to 5s. The recorder bumps liveness on
EVERY processed frame — saved, unchanged, or save-throttled — so a parent choosing
sparse evidence (say every 60s) changes nothing about how fast blocking returns when
recording stops or how fast a glitched session recovers. No safety or liveness
invariant may ever reference `screenshotInterval`.

- **Filter** — evaluates suspension state on EVERY flow decision, symmetrically:
  - suspension held & `live()` fails → end it (blocking resumes). *(exit, shipped)*
  - no suspension held & `live()` holds → re-enter it (blocking lifts). *(entry — D2,
    the trapdoor fix, shipped: `rederived` runs on every no-suspension flow decision)*
  - suspend sentinel (any Gertrude bundle id) & expiration future → enter with a
    `livenessWindow` grace, covering the moments before the first frame lands. The
    sentinel is an accelerator only; with D2 it is no longer load-bearing.
- **Controller** — evaluates the same `live()` from disk whenever it receives a flow:
  live → allow the flow + drain evidence (D1); not live → normal rule verdict. Already
  proven on device: the controller's per-flow re-derivation self-healed through every
  liveness gap that permanently trapped the filter's edge-triggered state.
- **App** — owns the grant state machine only: request → granted(duration) →
  (darwin start) write expiration + suspend sentinel → (darwin finish / user tap)
  clear expiration + resume sentinel + drain. If the app never hears the finish,
  the registers still converge (expiration lapses; tombstone kills liveness).
- **Recorder** — dumb by contract: save changed frames, bump liveness, emit darwin,
  tombstone on graceful stop. It must never gain responsibilities whose failure could
  kill the broadcast (the 50MB cap is the reason Chris's model died).

## Evidence pipeline (D1 — controller-primary, device-decided)

While `live()`: the filter summons the controller at a bounded cadence (target ~5s,
piggybacked on real flows) by verdicting `needRules`; the controller allows the flow
and uploads pending screenshots (fetch presigned URL, PUT from file, delete on 2xx).
The filter summons only when evidence is provably live — never on grace-only validity:
before the first frame there is nothing to drain, and the controller's stateless
`live()` check (which has no grace) would wrongly drop the delegated flow.
Hinge 3: 26/26 uploads, 378ms median, 44MB flat headroom, zero crashes. Evidence
latency while the child is active ≈ summon cadence + upload time — seconds, not
"whenever the app wakes" (hinge 2 measured that alternative at *never during the
session*).

Backstops, all opportunistic backlog cleanup only: app drain on foreground/darwin
events; controller drain on rule refreshes when recording is not live (shipped); any
bg-session wakes that happen to arrive. Upload semantics are **at-least-once** —
concurrent drainers may double-send a file; the filename is the dedup key and the
server side must treat re-PUTs as idempotent. A failed upload must not wedge a drain
loop's successors (observed: one 500 stranded 269 files — fix when productionizing the
drain: skip-and-continue with bounded attempts, not break).

## Invariants (checked by scenarios; explorer-enforced later)

- **S1 (safety):** a flow matching block rules is allowed only while a held suspension
  is valid: expiration in the future AND (evidence fresh within `livenessWindow` OR
  within the entry grace).
- **S2 (evidence):** every interval during which blocking was lifted has screenshots
  on disk covering it (≤5s granularity while the screen was on), each eventually
  uploaded exactly-once-per-filename to the parent.
- **L1 (fail-safe exit):** after evidence stops for any reason — memory-kill, reboot,
  screen off, spoofed entry — blocking resumes within `livenessWindow` + one flow.
- **L2 (recovery entry, new — the trapdoor's dual):** while expiration is in the
  future, evidence resuming (screen back on, frames flowing) lifts blocking again
  within `livenessWindow` + one flow, with no app involvement.
- **L3 (evidence latency):** while `live()` and traffic flows, every saved screenshot
  is uploaded within one summon cadence + upload time.
- **C1 (convergence):** from any reachable register state, processes launched in any
  order with no further user events reach: expiration lapsed/cleared, no suspension
  held, evidence backlog drained (given eventual controller CPU), blocking on.

## Failure matrix (required behavior; * = covered by existing LibSim scenario)

| Failure at t                         | Required behavior                                                                  |
| ------------------------------------ | ----------------------------------------------------------------------------------- |
| recorder memory-killed mid-recording | no tombstone, no darwin; L1 re-blocks ≤6s; leftovers drained by controller *        |
| device locked mid-recording          | iOS *finishes* the broadcast within ~3s (device-verified, side-button and auto-lock alike) → normal graceful-stop path: tombstone, darwin finish, grant consumed |
| frame delivery pauses ≥6s (system pause / memory pressure; NOT static screens — those keep delivering, D6 bumps them) | L1 re-blocks (correct: no evidence); L2 re-lifts when frames resume |
| app killed/suspended mid-recording   | zero protocol impact except UX + expiration-clear latency; registers converge *     |
| filter killed mid-suspension         | on-demand relaunch re-derives from disk (special case of D2/L2) *                   |
| controller killed mid-drain          | at-least-once uploads make partial drains safe; next summon resumes                 |
| reboot mid-suspension                | broadcast dies → no fresh evidence → blocked after relaunch, both boot orders *     |
| darwin start/finish lost             | entry via D2 level-trigger (slower by ≤1 flow); exit via tombstone/L1 *(partial)*   |
| suspend sentinel spoofed / replayed  | fan-out-idempotent; grace admits ≤6s unless real evidence flows (S1) *              |
| upload endpoint failing              | drains skip-and-continue; backlog bounded by disk; retried on every wake vector     |
| expiration lingers (app died)        | bounded by grant duration; gated by liveness the whole time (D3 — intended)         |

## Resolved decisions

- **D1** Evidence path: controller-primary via filter summoning; everything else is
  backlog cleanup. (Hinge 2 vs hinge 3, head-to-head on device.)
- **D2** Suspension entry becomes level-triggered like exit: filter re-derives on flow
  decisions whenever it holds no suspension (cheap: two register reads, 0ms observed
  cost), sentinel retained as accelerator + grace provider. (Trapdoor finding.) The
  lock/static validation showed normal use never gaps a live broadcast (locks end it,
  static screens keep bumping), so D2 is defense-in-depth for system pauses and filter
  relaunch, not a daily path — it stays, per S1/L2.
- **D3** A future expiration lingering after app death is intended, not a leak: it is
  exactly what makes L2 recovery and filter-relaunch re-derivation work, and it is
  gated by liveness at every instant. (Formerly an open "non-determinism" question;
  the trapdoor finding settled it.)
- **D4** `livenessWindow` stays 6s; propagation contributes ~0 of it. Liveness gaps
  while a broadcast lives are rarer than first thought (locks end the broadcast;
  static screens keep bumping under D6) but remain possible (system pause, memory
  pressure); handled by L1+L2 symmetry, not by widening.
- **D5** Uploads are at-least-once, filename-deduped; no cross-process drain locking.
- **D6** Liveness heartbeat (protocol, fixed 5s) and screenshot save cadence (policy,
  parent-configurable) are separate frequencies; the recorder bumps liveness per
  processed frame regardless of whether it saved. Safety/liveness math references only
  the heartbeat. (Prompted by making evidence density a parent setting.)

## Open (deliberately)

- Summon cadence/backoff when there is traffic but nothing to upload (wasted controller
  round-trips vs simplicity; measure, then tune).
- Whether the app's bg-session uploader earns its complexity at all once D1 lands, or
  gets deleted in favor of plain foreground drains.
- Silent push as a grant-time accelerator (design doc vector 2) — unexamined.
- Grant consumption policy: a device lock cleanly finishes the broadcast and burns the
  grant (device-verified), forcing a fresh parent request to continue. Restart-within-
  grant is representable on the current registers; undecided.
- Sim honesty upgrades still owed: a bg-URLSession OS actor if the uploader is kept.
  (App-suspension/darwin-coalescing R11-R12 gaps landed 2026-07-04; the R10 lock model
  was inverted same day after the validation session — `lockDevice()` finishes the
  broadcast, `pauseFrameDelivery()` models system pauses.)
