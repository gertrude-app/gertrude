# Phase 3: TCA / Composable Architecture on Android via Skip

## Summary Verdict

**TCA 1.x does NOT compile for Android today, but the path is clear and work is actively
in progress.** TCA 2.0 (in development) is being designed from the ground up to be
platform-agnostic. For the AM app's use of TCA, this is a **hard blocker in the short
term** — but not necessarily a permanent one.

---

## Evidence

### 1. TCA Package.swift — Platform Declaration

`https://raw.githubusercontent.com/pointfreeco/swift-composable-architecture/main/Package.swift`

```swift
platforms: [
  .iOS(.v16),
  .macOS(.v13),
  .tvOS(.v16),
  .watchOS(.v9),
],
```

Android is absent. The package makes no provision for Android in its declaration. Swift
Package Manager will refuse to resolve this package when targeting Android unless this is
patched.

### 2. TCA's Core Sources — Direct SwiftUI and Combine Imports

`Sources/ComposableArchitecture/Store.swift` (main branch, current):
```swift
import Combine
import CombineSchedulers
import Foundation
import SwiftUI   // ← unconditional, top-level
```

`Sources/ComposableArchitecture/Core.swift`:
```swift
import Combine
import Foundation
```

`Sources/ComposableArchitecture/Effect.swift`:
```swift
@preconcurrency import Combine
import Foundation
import SwiftUI   // ← unconditional, top-level
```

Both `Combine` and `SwiftUI` are imported unconditionally at the top of key files. These
frameworks do not exist on Android. This causes immediate compile failure.

### 3. The WIP Android PR — What Exists, What Doesn't

**PR #3805** "WIP Android support"
- Author: Joannis (community member, not Point-Free staff)
- Opened: 2025-10-25, Closed (not merged): 2025-12-09
- Branch: `Joannis:jo/android-support`
- URL: https://github.com/pointfreeco/swift-composable-architecture/pull/3805

**What the PR did:**
- Added `OpenCombine` as a dependency for Android/Linux
- Wrapped `import Combine` / `import SwiftUI` with `#if canImport(Combine)` and
  `#if os(macOS) || os(iOS) || ...` guards throughout the codebase
- Removed unconditional `SwiftUI` import from `Effect.swift` and `Store.swift`
- Guarded `UIScheduler`, `Animation`, `Transaction` usage behind OS checks
- Added `#else import OpenCombine` fallbacks

The PR modified ~70 files to surgically add these guards. It was a significant undertaking.

**Why it was closed:**
From the PR comment thread (stephencelis, Point-Free co-founder, 2025-10-27):

> "We are enthusiastic about this initiative... As a side note, we are currently in the
> process of designing 2.0 of the Composable Architecture, which is being approached from
> **first principles with modern Swift and platform agnostics, i.e. no dependence on
> Combine or other Apple-only frameworks.** It may be a few months before any of it sees
> daylight, though..."

Joannis then closed the PR on 2025-12-09 with:
> "I'll close this for now. 2.0 will be much better"

**CI status of the PR:** The PR was in "dirty" (merge conflict) state and had no CI runs
recorded, so it is unknown whether it compiled successfully for Android.

### 4. The Author's Diagnosis — `#if canImport` Doesn't Work Reliably

From the PR description:
> "This is still WIP, for some reason the Swift compiler doesn't respect `#if os(..)` that
> well."

This is a known issue with Swift for Android cross-compilation: conditional compilation
blocks keyed on `#if canImport(SwiftUI)` or `#if os(iOS)` don't always behave as expected
when cross-compiling from macOS.

### 5. TCA's Key Dependencies — Their Android Status

| Dependency | Platform Restriction | Android Status |
|---|---|---|
| `combine-schedulers` | Apple platforms declared | Has open PRs for Android (#113, #114); uses trait-based OpenCombine shim but traits don't work transitively in cross-compilation |
| `swift-dependencies` | Apple platforms declared | No Android work found; uses Combine transitively via combine-schedulers |
| `swift-navigation` | Apple platforms declared; includes `SwiftUINavigation`, `UIKitNavigation` | Not Android-compatible |
| `swift-sharing` | Apple platforms declared | Uses `#if canImport(AppKit) || canImport(UIKit)` guards for AppStorage key, but rest may be portable |
| `swift-perception` | Apple platforms declared | Core may be portable (no Combine import found); exports `PerceptionCore` unconditionally |
| `swift-clocks` | Apple platforms declared | Likely portable (uses Swift Concurrency `Clock` protocol) |
| `swift-concurrency-extras` | Not found restricted | Likely portable |

**combine-schedulers is the most acute transitive blocker.** From issue #110:
> "Unfortunately traits don't appear to work transitively, so when including
> `combine-schedulers` as a dependency to `swift-dependencies`... I can't pass the trait"
> (the trait enables OpenCombine on non-Darwin)

This means even `swift-dependencies` (a lighter, non-UI TCA dependency) fails to build
for Android because of this trait-propagation limitation in Swift Package Manager.

### 6. TCA 2.0 — The Intended Fix

Point-Free has announced TCA 2.0 at:
- https://www.pointfree.co/blog/posts/200-the-point-free-way-tca-2-0-sneak-peek-a-giveaway-q-a-and-more

Confirmed goals from stephencelis' PR comment:
- "platform agnostics"
- "no dependence on Combine or other Apple-only frameworks"
- "being approached from first principles with modern Swift"

As of March 2026, no TCA 2.0 public release or beta is available. Point-Free said "early
next year" (from their Dec 2025 comment), which suggests Q1-Q2 2026. No branch or tag is
publicly visible yet.

---

## swift-dependencies Alone

If the AM app could be refactored to use only `swift-dependencies` (not full TCA), this
would be a narrower problem. `swift-dependencies` itself (Package.swift) lists only Apple
platforms and depends on `combine-schedulers`. The combine-schedulers Android trait issue
is a blocker here too. No Android-specific PRs exist on `swift-dependencies`.

**Verdict on swift-dependencies standalone:** Not currently buildable for Android without
patching combine-schedulers and swift-dependencies directly.

---

## Skip's Own Approach to Observation / State

Skip provides `skip-model` (https://github.com/skiptools/skip-model), which implements
`@Observable`, `ObservableObject`, and Combine support for Android. Its Package.swift
shows:

```swift
#if !canImport(Combine)
  // on Linux we need to import OpenCombine to get ObservableObject
  package.dependencies += [.package(url: "https://github.com/OpenSwiftUIProject/OpenCombine.git", ...)]
#endif
```

This means Skip's own state management layer handles the Combine substitution. The AM
app's reducers, if rewritten against Skip's observation layer directly (without TCA), would
likely compile.

---

## Workaround Options

### Option A: Wait for TCA 2.0
- ETA: Unknown, likely mid-2026 at earliest (no public branch as of March 2026)
- Risk: Point-Free hasn't committed to an Android-first release; "platform agnostic" may
  mean Linux/Windows but not necessarily Android
- Best case: TCA 2.0 compiles on Android and the AM app's reducers port with minimal changes

### Option B: Patch TCA 1.x (Fork + #if guards)
- Joannis' PR is the starting point (~70 file changes)
- The PR wasn't confirmed to compile successfully
- The `#if canImport(SwiftUI)` reliability issue on cross-compilation is a real concern
- combine-schedulers also needs patching for traits to work
- Maintenance burden: any TCA update requires re-applying patches
- **Effort: High; Reliability: Unknown**

### Option C: Use Only the Reducer/Logic Layer, Skip TCA Views
- TCA's core value for the AM app is the Reducer + Store pattern, not the SwiftUI bindings
- The `SwiftUI/` subdirectory of TCA (all the view helpers) can be entirely excluded
- A fork that removes `import SwiftUI` from non-UI files and stubs SwiftUI-only APIs behind
  `#if canImport(SwiftUI)` could make the reducer layer compile
- The AM app would need Android-specific views using Skip's SkipUI instead of TCA's view layer
- **Effort: Medium; Reliability: Better than Option B**

### Option D: Replace TCA with a Simpler Pattern
- Rewrite AM app state management using `@Observable` + `@Environment` (supported by
  SkipModel / skip-model)
- This is essentially what TCA 2.0 will likely move toward
- For a podcast app (not an enterprise app), TCA's full machinery may be overkill
- **Effort: High (rewrite); Reliability: High**

---

## sqlite-data Situation

`sqlite-data` requires `GRDB.swift >= 7.6.0`. GRDB **v7.10.0** (released 2026-02-15)
explicitly added Android, Linux, and Windows support:

> "This release focuses on bringing GRDB to Android, Linux, and Windows."

sqlite-data's Package.swift also lists only Apple platforms, but its core dependency (GRDB)
now supports Android. However:
- sqlite-data's own `platforms:` declaration blocks Android resolution
- sqlite-data's sources likely need the same `#if canImport` guard treatment for any
  UIKit/AppKit-specific keys (AppStorage etc.)
- The GRDB Android support is there as of 7.10.0, so once sqlite-data itself is patched,
  the SQLite layer could work on Android

**Skip's alternative:** `skip-sql` (https://github.com/skiptools/skip-sql) provides a
SQLite interface natively for Skip apps on both iOS and Android. If the AM app's data layer
could be abstracted behind a protocol, skip-sql could serve as the Android implementation.
This is the cleaner path than patching sqlite-data.

---

## What No One Has Done Yet

Despite all this research, no one has published:
- A working fork of TCA that compiles for Android via Skip
- A working example app using TCA on Android via the Swift SDK
- A confirmed "TCA + Skip" success story anywhere on GitHub, Skip forums, or the web

The community is clearly trying (PR #3805 on TCA, PRs #103/#113/#114 on combine-schedulers,
issue #110 on combine-schedulers), but as of March 2026 no one has crossed the finish line.

---

## Specific Compiler Error You Would See Today

If you attempted to add TCA to a Skip project targeting Android, you would see errors like:

1. **Package resolution failure:** Package.swift platform restriction excludes Android
2. **If you forced it:** `error: no such module 'Combine'` (from `import Combine` in
   Core.swift, Store.swift, Effect.swift)
3. **If you substituted OpenCombine:** `error: no such module 'SwiftUI'` (from unconditional
   `import SwiftUI` in Store.swift, Effect.swift)
4. **Even after fixing SwiftUI:** Chain of `UIScheduler`, `Animation`, `Transaction`,
   `withTransaction` errors throughout the codebase

---

## Bottom Line

| Question | Answer |
|---|---|
| Does TCA 1.x compile for Android today? | **No** |
| Does TCA's Package.swift restrict to Apple platforms? | **Yes** (iOS 16+, macOS 13+, tvOS 16+, watchOS 9+) |
| Does TCA import SwiftUI unconditionally in non-UI parts? | **Yes** — Store.swift, Effect.swift both `import SwiftUI` at top level |
| Has anyone successfully gotten TCA to compile with Swift for Android? | **No confirmed case** |
| Is there a workaround? | **WIP fork (Joannis' PR), unconfirmed; TCA 2.0 intended to solve this** |
| Is swift-dependencies alone buildable for Android? | **No** — combine-schedulers trait issue blocks it |
| Is the underlying SQLite (GRDB) layer usable on Android? | **Yes, as of GRDB 7.10.0 (Feb 2026)** — but sqlite-data itself still needs patching |

**Recommendation:** Do not attempt to port the AM app using TCA 1.x + Skip in its current
state. The effort to patch TCA and its dependency chain is high, and the result would be a
fragile fork. Either wait for TCA 2.0 (unknown timeline, likely mid-2026), or architect
the Android port to use Skip's own `@Observable` state management and bypass TCA entirely
for the Android target, using a shared pure-Swift reducer layer that avoids TCA's SwiftUI
integration points.
