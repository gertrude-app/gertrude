# MacSim Maintenance Contract

MacSim is maintained infrastructure, not a one-off test fixture. A PR that
changes production behavior modeled by MacSim must update the simulator,
evidence, and tests together.

## Required For New Modeled Behavior

Every new behavior that affects simulated verdicts or app/filter convergence
needs all of:

- A modeled rule in `VirtualMac`, `MacExplorer`, or the relevant scenario.
- A checker: a named scenario, oracle assertion, convergence assertion, or
  non-vacuity counter.
- Evidence in `vm-witness-findings.md` when the behavior comes from macOS or
  NetworkExtension, or a `sync:<id>` marker pair when the behavior mirrors
  Gertrude production Swift.
- A row or note in the conformance docs explaining the evidence basis and
  remaining gaps.

## `sync:<id>` Markers

Prefer sharing over mirroring: when simulator and production need the same
policy data structure or constant, extract it (e.g. `Core.UserConnectionMap`
for per-user XPC routing, `Filter.appAlivenessSeconds` and
`Filter.heartbeatIntervalSeconds` for the oracle's timing) so drift is
impossible. Use a marker only for behavior that must stay *mirrored* — oracle
replay logic, which is intentionally an independent reimplementation, and
simulated OS delivery/lifecycle around shared policy.

Use lowercase `sync:` with no space before the id:

```swift
// sync:<id> short behavior label
```

Mint ids with `sid --llm`. Use the same id on every simulator and production
site that must stay behaviorally aligned. Keep the inline label short and
stable; do not put file names or function names in the comment.

When touching a marked site:

1. Run `rg "sync:<id>"`.
2. Audit every match in the same PR.
3. Update the simulator, production code, tests, and conformance docs together
   when the contract changes.

The grep result is the registry. Do not add a separate central list unless a
future workflow needs one.

## Re-Conformance Triggers

Revisit the evidence and run the relevant witness path when any of these change:

- A new macOS major version used by supported customers.
- NetworkExtension flow delivery, provider lifecycle, or XPC behavior changes.
- App/filter message contracts, liveness windows, heartbeat intervals, or
  persistence semantics change.
- The explorer starts modeling a new dimension such as schedules,
  always-blocked rules, app migration, sleep/wake, or app-driven extension
  state changes.

## CI Contract

- Per PR: run `just macsim-test`.
- Nightly/manual seed hunt: run `just macsim-hunt`.
- Freeze minimized failing scripts as named regression scenarios.
- Treat `MacSeededRNG` output as stable. Changing it invalidates historical
  seed references and requires explicit review.

If a MacSim or full-suite run flakes, capture the full output before rerunning.
