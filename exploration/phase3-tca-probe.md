# Phase 3: TCA (The Composable Architecture) Probe — Build Proof

> See also: `phase3-tca.md` for the full theoretical analysis, TCA 2.0 status, and workaround options. This document is the empirical proof confirming the findings from that research.

## Verdict: HARD BLOCKER — Does Not Build for Android

TCA fails to compile for Android with a hard, unfixable error in a transitive dependency.

## What Was Tested

Probe package at `exploration/phase3/tca-probe/` with:
- `swift-composable-architecture` from `1.25.0` (same as AM app)
- A minimal counter feature (`CounterFeature` with State/Action/Reducer)
- Skip `native` mode

## Build Command

```bash
source ~/.swiftly/env.sh && PATH="$(brew --prefix openjdk@17)/bin:$HOME/skip-bundle/bin:/opt/homebrew/bin:$PATH" \
  JAVA_HOME=$(brew --prefix openjdk@17) ANDROID_HOME=~/Library/Android/sdk \
  ~/skip-bundle/bin/skip android build \
  --package-path exploration/phase3/tca-probe --product TCAProbe
```

## Failure

Build fails in `combine-schedulers` (a transitive dependency of `swift-dependencies`, which TCA depends on). The error is:

```
combine-schedulers/Sources/CombineSchedulers/Timer.swift:23:13: error: cannot find type 'Scheduler' in scope
combine-schedulers/Sources/CombineSchedulers/Timer.swift:44:13: error: cannot find type 'Publishers' in scope
combine-schedulers/Sources/CombineSchedulers/Timer.swift:249:34: error: cannot find type 'Publishers' in scope
combine-schedulers/Sources/CombineSchedulers/Timer.swift:256:34: error: cannot find type 'Cancellable' in scope
```

The `combine-schedulers` library uses Combine types (`Publishers`, `Scheduler`, `Subscriber`, `Cancellable`, `CombineIdentifier`) unconditionally — these don't exist on Android.

## Dependency Chain

```
TCAProbe
└── swift-composable-architecture (1.25.0+)
    └── swift-dependencies (1.11.0)
        └── combine-schedulers (1.1.0)   <-- FAILS HERE
            └── Combine (Apple-only framework)
```

## Why It Fails

`combine-schedulers` contains a `Timer.swift` file that directly references Combine types with no platform guards. On Android, Combine doesn't exist, so every Combine type reference fails with "cannot find type in scope".

This is not a trivial wrapping issue. The `combine-schedulers` library is deeply integrated into `swift-dependencies`, which is itself a core dependency of TCA.

## Could It Be Fixed?

No, not without forking. Options:

1. **Fork `combine-schedulers`** and `#if canImport(Combine)` guard the Timer.swift code — but this would need to be maintained upstream and is not under our control.
2. **Vendor the dependency and patch it** — possible as a hacky workaround, but you'd have to do this for every PFW package update.
3. **Wait for upstream fixes** — the PFW team would need to add Android/Linux platform guards to `combine-schedulers`. There's no indication this is planned.
4. **Build TCA from scratch without combine-schedulers** — i.e., not use the actual TCA library at all, just the architectural pattern.

## Impact on AM App

This is a **complete blocker** for using TCA on Android. The AM app uses TCA for all state management. You cannot bring TCA to Android as-is. The options are:

- **Port without TCA**: Rewrite state management using a different pattern (plain `@Observable`, vanilla async/await, or a hand-rolled reducer). Skip's `SkipModel` provides `@Observable` support natively.
- **Seam it**: The business logic layer could use TCA on iOS while Android gets a different implementation of the same interface. This is the most realistic path but requires significant architectural seams.

## Notes

- The `skip.yml` file must be present in `Sources/<Target>/Skip/` for Skip to process the module — this was a gotcha discovered during this probe (see phase2.md).
- TCA's macros (`@Reducer`, `@ObservableState`) require `swift-syntax`, which pulled in 602.0.0 during resolution. This compiled fine — macros are not the blocker.
- The blocker is purely at the Combine dependency level.
