# Screenshot timer lifecycle: dependency-owned actor instead of TCA cancellation

- Date: 2026-05-16

## Context

A customer on a shared-family iMac using Fast User Switching reported the mac app
capturing screenshots ~10–12x per second despite a configured frequency of 120s. The DB
confirmed sustained bursts of real over-capture (client-side `createdAt` timestamps
clustered within single seconds), not delayed upload of a backlog.

The screenshot timer was previously a `for await _ in bgQueue.timer(...)` loop living
inside a reducer effect, wrapped in
`.cancellable(id: CancelId.screenshots, cancelInFlight: true)`. Every trigger path routed
through `configureMonitoring`, which cancelled the prior effect and started a new one.

The single-timer guarantee depended on `.cancellable(cancelInFlight:)` tearing down the
previous timer before the next could fire. In practice that teardown is **not**
synchronous: Swift task cancellation is cooperative, and the underlying
`DispatchSourceTimer` only tears down once `AsyncStream.onTermination` fires. That leaves
a window where, on a sluggish/contested machine (or during an FUS handoff), a new timer
can begin firing before the old one has stopped — two (or more) concurrent timers, each
driving `takeScreenshot`. The exact trigger was not pinned down by code reading, but the
data shows the contract being violated.

## Decision

Move the timer's lifecycle behind a single dependency-owned actor,
`ScreenshotTimerController` (resolved via `@Dependency(\.screenshotTimer)`; `liveValue` is
a shared singleton, `testValue` is fresh per store for test isolation). Two layers of
defense:

1. **Layer 1 — structural single-timer guarantee.** `reconfigure(...)` cancels the
   previous timer Task and **`await`s its full unwind**
   (`task?.cancel(); await task?.value`) before installing the next one, closing the
   cooperative-cancellation window the old model could not. A monotonically increasing
   `generation` tag, captured before the `await` and re-checked after, makes the actor
   safe under reentrancy (the `await` is a suspension point at which another
   `reconfigure`/`stop` can run): a superseded transition bails instead of installing or
   clobbering a second timer. `stop()` participates in the same generation protocol.

2. **Layer 2 — capture-site rate floor.** `takeScreenshot` refuses to capture more than
   once per `minScreenshotIntervalSec` (10s) via a single atomic check-and-set
   (`ScreenshotFloor`). 10s is the server-enforced minimum configurable frequency, so it
   constrains no legitimate operation (lowest real customer setting is 10s) while capping
   catastrophic failure at ~6/min instead of ~12/sec.

The reducer's `configureMonitoring` and the teardown action cases call into the actor; the
`CancelId.screenshots` machinery is removed.

## Alternatives considered

- **Keep `.cancellable`, just harden it.** Rejected: the cooperative cancellation +
  `DispatchSourceTimer` teardown race is intrinsic to that model; there is no reliable way
  to make `cancelInFlight` tear the old timer down _before_ the new one starts. This is
  the model that produced the bug.

- **Actor does capture+upload directly (no action round-trip).** Rejected: the reducer
  reads `state.isFilterSuspended` and `screenshotSize` fresh on each
  `.timerTriggeredTakeScreenshot`. A plain filter suspension with no extra monitoring does
  not route through `configureMonitoring`, so capturing those values at `reconfigure` time
  would record screenshots with a stale `filterSuspended` flag, regressing suspension
  attribution. The actor's `fire` closure therefore only sends the action; the reducer
  keeps reading fresh state.

- **`@globalActor` / bare global like `screenshotBuffer`.** Rejected: no need for
  compile-time global-actor isolation, and a process-global instance leaks state across
  tests (the same-interval no-op short-circuits subsequent tests). `screenshotBuffer` only
  survives as a global because tests spy it out via the `monitoring` dependency; the timer
  is invoked directly by the reducer, so it must be injected to be test-isolated.

## Consequences

- **Stronger guarantee than before.** "At most one timer Task exists" is now enforced by
  construction (cancel → await teardown → generation-guarded install), a property the old
  `.cancellable` model could not provide.

- **Relocated, not eliminated, invariant.** The timer Task is no longer effect-scoped, so
  TCA effect teardown (incl. store deinit) does **not** stop it. Correctness depends on
  every lifecycle transition explicitly calling `stop()`/`reconfigure()`. This convention
  is bounded and test-covered: the teardown paths are a small enumerable set (disconnect,
  `userDeleted`, `willTerminate`, no-user, screenshots-disabled) and
  `MonitoringFeatureTests` asserts capture stops on each. A future path that forgets
  `stop()` will, in the realistic cases, break an existing test.

- **Layer 2 is the intentional backstop for that convention.** It exists precisely because
  Layer 1's single-timer property is convention-bound and could be violated by a future
  regression or a new direct caller of `takeScreenshot` (two such paths already exist in
  onboarding). Even if Layer 1 is someday broken, over-capture is capped at ~6/min by
  construction.

- **Reentrancy is subtle.** The first implementation of `stop()` lacked the generation
  guard and could orphan a newly-created timer when racing a concurrent `reconfigure()`.
  Fixed, and pinned by `testStopRacingReconfigureLeavesNoOrphanTimer` (verified to fail
  25/25 iterations against the pre-fix `stop()`). Any change to the actor's
  cancel/await/generation logic must preserve this; keep that test.

- **Arbitration is by order-of-entry, not logical intent order.** When a `stop()` and a
  `reconfigure()` race, "latest generation wins" resolves by which entered the actor's
  synchronous prologue first. This is a reasonable proxy; `configureMonitoring` is
  re-driven on state changes so a transiently wrong winner self-corrects, and Layer 2 caps
  any residual misbehavior. Strict logical ordering would require serializing transitions
  through a queue and is not judged worthwhile given the backstop.

## Not addressed (future work)

- `DeviceClient.currentUserHasScreen()` falls back to "true if console uid == 0"
  (loginwindow / mid-FUS). During an FUS handoff all users' instances briefly believe they
  have the screen; likely a contributor to the original trigger. Separate concern (the
  "who has the screen" semantics during FUS), not fixed here.
