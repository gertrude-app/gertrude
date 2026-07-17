# MacSim: a maintained simulated-OS harness with a conformance loop

- Date: 2026-07-17

## Context

The mac app's highest-risk behavior is concurrent, multi-process, and stateful: filter
flow verdicts, app ↔ filter XPC convergence, durable-state reload across provider crash
and reboot, liveness windows, suspension/downtime timing, and per-user connection routing.
The app and filter share no durable container — state converges only through
connection-oriented XPC — so correctness is a property of _interleavings_, not of either
side alone.

This surface was historically under-tested for structural reasons:

- Per-reducer unit tests (TCA `TestStore`) verify each process in isolation. The bug
  classes that reached production were invisible to them because each side was
  individually "correct": the filter losing persisted downtime on provider relaunch, and
  filter-to-app XPC failures throwing out of effects instead of being best-effort.
- Real-device/VM integration tests of a NetworkExtension system extension are slow,
  non-deterministic, need privileged setup plus GUI onboarding approval, and cannot
  control time — which downtime windows, the 150s liveness window, and 60s heartbeats all
  depend on — or reproduce process-crash interleavings on demand.

A July 2026 feasibility effort built a deterministic simulation harness that found both of
the production bugs above, forcing the real decision: adopt it as maintained
infrastructure, or let it rot as a one-off campaign artifact.

## Decision

Maintain MacSim in-tree as tested infrastructure (`swift/macapp/App/Tests/MacSimTests`,
docs in `swift/macapp/conformance/`):

- `VirtualMac` models the OS world explicitly — pinned clock (epoch 2025-01-01Z), per-user
  defaults domains, per-user XPC transport, process lifecycle including crash / reboot /
  relaunch, and NetworkExtension flow delivery — and drives the **real** filter reducer,
  `FilterProxy`, and app reducers through their existing `@Dependency` seams.
- `MacExplorer` runs seeded random interleavings and checks every observed flow verdict
  against an independent oracle replayed from the delivered app-to-filter message log.
  Failing seeds shrink to committed regression scenarios; CI runs scenarios plus a small
  corpus per PR (`just macsim-test`) and larger hunts nightly (`just macsim-hunt`).

Because the simulator is a _model of two realities_ — macOS behavior, and Gertrude code
below the dependency seam — it is paired with a conformance loop that keeps the model
honest:

- Modeled **OS behavior** requires a VM witness, recorded in `vm-witness-findings.md`.
- Mirrored **Gertrude code** is shared outright where possible (`Core.UserConnectionMap`
  routing policy, `Filter.appAlivenessSeconds` / `heartbeatIntervalSeconds`) and marked
  with paired `sync:<id>` comments where mirroring is essential (oracle replay logic,
  simulated delivery around shared policy).
- `maintenance-contract.md` binds model + evidence + checker updates into any PR that
  changes modeled behavior, and defines re-conformance triggers (new macOS majors, etc.).

## Alternatives considered

- **VM/device end-to-end tests as the primary harness.** Rejected for the reasons above
  (non-determinism, minutes per scenario, no time control). But not discarded: the VM is
  the _witness_ mechanism. The conformance loop is exactly this division of labor — a VM
  run proves an individual OS claim once; the simulator then exercises combinatorial
  interleavings of witnessed behaviors forever, deterministically.

- **More unit tests instead.** Cannot express cross-process convergence properties, and
  demonstrably missed the bug classes at stake. Unit tests remain the right tool for
  everything MacSim deliberately excludes (see the scope statement in `mac-explorer.md`).

- **Push the simulation boundary lower** (protocolize `NSXPCConnection`/`NSXPCListener`
  and run the real live clients in the sim, FoundationDB-style). Rejected: invasive
  refactoring of security-critical NSXPC code (reply-block proxies, invalidation handlers,
  code-signing requirements), and the resulting shim would itself embody unverified
  assumptions about NSXPC. Cutting at the existing TCA dependency seam cost zero
  production refactoring; the residual mirroring it creates is managed by shared
  types/constants first, `sync:` markers second.

- **Keep the harness on a branch / in the lab repo until "complete."** Rejected: an
  unmerged model of a moving codebase rots silently. This happened during the harness's
  own gestation — production XPC routing changed from last-wins to a per-user map while
  the simulator kept modeling last-wins and stayed green. Merged, the maintenance contract
  inverts the arrow: PRs that change modeled behavior must move the model.

## Consequences

- **A green MacSim run is not whole-app verification.** The modeled alphabet is
  deliberately small; `mac-explorer.md` carries an explicit scope statement. The priority
  expansions are the verdict-adjacent dimensions the oracle does not yet model
  (exemptions, filtering-disabled, always-blocked, schedules).
- **Ongoing tax, by design.** Changing filter verdict, XPC, persistence, liveness, or
  timing behavior now obligates simulator + evidence + doc updates in the same PR, and new
  macOS majors trigger re-conformance. This is the price of the model staying true; the
  contract exists so the price is paid incrementally instead of in another silent drift.
- **Trust rests on the loop, not the sim.** Non-vacuity is demonstrated by the sabotage
  table in `mac-explorer.md` (seeded bugs, measured catch); a `uid < 500` precondition
  guards against DEBUG verdict inversion on system-uid CI runners.
- **Determinism is a hard commitment.** The pinned epoch and stable `MacSeededRNG` mean
  every historical failing seed reproduces forever; changing either invalidates the
  regression corpus and requires explicit review.
