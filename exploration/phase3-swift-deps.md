# Phase 3: swift-dependencies Probe

## Verdict: HARD BLOCKER — Same Combine Problem as TCA

`swift-dependencies` fails to build for Android for the exact same reason as TCA: its transitive dependency `combine-schedulers` uses Combine types unconditionally.

## What Was Tested

Probe package at `exploration/phase3/deps-probe/` with:
- `swift-dependencies` version `1.10.0+` (latest resolved: 1.11.0)
- A simple `AudioPlayerClient` dependency modeled after the AM app's real client
- Skip `native` mode

## Build Command

```bash
source ~/.swiftly/env.sh && PATH="$(brew --prefix openjdk@17)/bin:$HOME/skip-bundle/bin:/opt/homebrew/bin:$PATH" \
  JAVA_HOME=$(brew --prefix openjdk@17) ANDROID_HOME=~/Library/Android/sdk \
  ~/skip-bundle/bin/skip android build \
  --package-path exploration/phase3/deps-probe --product DepsProbe
```

## Failure

Identical to TCA probe — fails in `combine-schedulers`:

```
combine-schedulers/Sources/CombineSchedulers/Timer.swift:23:13: error: cannot find type 'Scheduler' in scope
combine-schedulers/Sources/CombineSchedulers/Timer.swift:44:13: error: cannot find type 'Publishers' in scope
combine-schedulers/Sources/CombineSchedulers/Timer.swift:249:34: error: cannot find type 'Publishers' in scope
combine-schedulers/Sources/CombineSchedulers/Timer.swift:256:34: error: cannot find type 'Cancellable' in scope
```

## Dependency Chain

```
DepsProbe
└── swift-dependencies (1.11.0)
    └── combine-schedulers (1.1.0)   <-- FAILS HERE
        └── Combine (Apple-only)
```

## This Is the Same Root Cause as TCA

Both `swift-dependencies` and TCA pull in `combine-schedulers`. The blocker is identical:
`combine-schedulers/Sources/CombineSchedulers/Timer.swift` uses Combine types without `#if canImport(Combine)` guards.

## Impact

`swift-dependencies` is the PFW dependency injection library used throughout the AM app for:
- `AudioPlayerClient` — audio playback
- `DatabaseClient` — SQLite access
- `APIClient` — network calls
- All other testable/injectable dependencies

Since it cannot be imported on Android, the entire dependency injection layer of the AM app would need to be replaced.

## Silver Lining: The Pattern Ports Fine

The `swift-dependencies` *pattern* — defining a struct of closures, registering with `DependencyValues`, and injecting with `@Dependency` — is trivially portable. The issue is not the concept, it's the specific library implementation.

On Android/Skip, you can achieve the same pattern using:
- Swift's `@Observable` + simple protocols
- Manual dependency injection via environment objects
- A lightweight hand-rolled DI container

The AM app's dependency types (structs of closures conforming to a key) are a pattern, and that pattern can be reproduced without the PFW library.

## Could combine-schedulers Be Fixed?

The fix would be trivial: wrap the Combine-dependent code in `#if canImport(Combine)`. The PR would be a few lines. However:
- This hasn't been done yet by PFW team
- `swift-clocks` 1.0.x (also in the dep chain) has some Combine references too
- Even if fixed upstream, you'd need to wait for a new release and update the dependency

Filing an issue/PR on `combine-schedulers` is low-cost and could pay off, but shouldn't be counted on for near-term work.

## Summary

`swift-dependencies` is blocked on Android for the same reason as TCA. Both are unfixable without upstream changes to `combine-schedulers`. The DI pattern they implement is portable, but the library itself is not.
