# Skip Android Feasibility: Summary Assessment

**App:** Gertrude AM (podcast player)
**Framework:** Skip (Fuse/native mode)
**Date:** 2026-03-21
**Phases completed:** 1 (research), 2 (hello world), 3 (gnarliest bits: TCA, SQLite, audio)

---

## Verdict: YES, BUT — Feasible with Significant Architectural Work

Porting the AM app to Android via Skip is **technically feasible** but requires a substantial
rewrite of the app's core architecture. The framework works. The blockers are all in the AM
app's dependency choices (Point-Free libraries), not in Skip itself.

---

## The Three Hard Realities

### 1. TCA is a Hard Blocker

The Composable Architecture (1.25.0) **cannot build for Android**. The failure is not in TCA
itself but in its transitive dependency `combine-schedulers`, which uses Combine types
(`Publishers`, `Scheduler`, `Cancellable`) unconditionally without platform guards. These don't
exist on Android.

**Dependency chain:**
```
TCA → swift-dependencies → combine-schedulers → Combine (Apple only) → FAILS
```

`swift-dependencies` alone fails for the same reason. There is no workaround short of forking
upstream packages. This is empirically confirmed (see `phase3-tca-probe.md`).

**Impact:** The AM app uses TCA for all state management. The entire TCA layer must be replaced
for Android. This is the single largest piece of work.

### 2. The Audio Layer Needs Custom Android Work

SkipAV exists and works for basic playback. `AVPlayer`, `AVAudioPlayer`, playback rate, seek,
volume, and completion notifications all function via ExoPlayer on Android.

**What's missing:**
- `addPeriodicTimeObserver` — the progress tick mechanism (needed for the progress bar)
- `AVAudioSession` — background audio continuation and interruption handling (phone calls)
- `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter` — lock screen controls and now-playing info

None of these are hard blockers — each has a well-known Android equivalent — but each requires
native Android code in `#if SKIP` blocks. Total estimated effort: 4–7 days.

### 3. SQLite Needs Replacing (but There's a Good Option)

The AM app uses `sqlite-data` (Point-Free, Apple-only) — dead on arrival. GRDB fails too
(`sqlite3.h` is absent from the Swift Android SDK sysroot).

**The fix:** Skip's own `skip-sql` package (`SkipSQLPlus`) bundles the SQLite amalgamation
directly and builds cleanly for Android. Confirmed BUILD SUCCESSFUL in probe (see
`phase3-skip-sql.md`). The tradeoff is migrating from GRDB's API to Skip's SQL wrapper.

---

## What Works Today (No Effort Required)

- Skip Fuse native mode builds and runs on Android ✓
- SwiftUI views transpile to Jetpack Compose via Skip ✓
- `@Observable` state management works natively ✓
- Foundation APIs (`Date`, `URL`, `JSONEncoder/Decoder`, `FileManager`) work ✓
- Basic audio playback via SkipAV (play/pause/seek/rate) ✓
- SQLite CRUD via skip-sql ✓
- Platform-specific code via `#if SKIP` and `#if os(Android)` ✓
- JNI bridge for native Swift↔Kotlin interop ✓

---

## Architecture Rethink Required

The AM app's architecture is tightly coupled to Point-Free's ecosystem:

| Current AM App | Android Reality |
|----------------|-----------------|
| TCA reducers + `@Reducer` | Must rewrite with `@Observable` or hand-rolled reducer |
| `swift-dependencies` DI | Must use protocol-based DI or plain singletons |
| `AudioPlayer` dependency (TCA client) | Must build separate iOS + Android live implementations |
| `sqlite-data` (PFW) | Must migrate to `skip-sql` |
| GRDB | Must migrate to `skip-sql` |
| CloudKit sync (if any) | Android has no CloudKit; would need separate backend |

### The Natural Architecture for Cross-Platform AM

```
shared/
  Models.swift          ← @Observable, no TCA deps
  EpisodeList.swift     ← SwiftUI views (shared)
  PlayerView.swift      ← SwiftUI views (shared)
  AudioPlayerProtocol.swift ← protocol seam

iOS/
  AudioPlayer+iOS.swift ← AVPlayer + AVAudioSession + MPRemoteCommandCenter

Android/  (in #if SKIP blocks)
  AudioPlayer+Android.swift ← SkipAV + AudioManager + MediaSession (native service)
```

Views can be shared almost completely. Business logic can be shared if rewritten without TCA.
The audio engine needs a full dual implementation.

---

## Phase 2 Build Workflow (Key Insight)

Skip Fuse native mode requires a non-obvious two-step build:

1. **iOS first:** `xcodebuild` generates Kotlin bridge `.kt` files via the skipstone plugin
2. **Android second:** `gradle assembleDebug` with `BUILT_PRODUCTS_DIR` pointing to DerivedData

Running `skip android build` alone is insufficient — it does not generate Kotlin bridge files.
This is a meaningful workflow constraint for CI/CD and developer experience.

Full workflow documented in `phase2.md`.

---

## Effort Estimate

This is a rough breakdown assuming one senior developer familiar with both Swift and some Android:

| Area | Effort | Notes |
|------|--------|-------|
| Replace TCA state management | 2–4 weeks | Most of the app's logic layer |
| Audio layer (iOS + Android implementations) | 1–2 weeks | Mostly Android plumbing |
| Migrate SQLite to skip-sql | 1 week | API translation, schema unchanged |
| SwiftUI views (shared, minimal changes) | 1–2 weeks | Some `#if os(Android)` tweaks |
| Android app shell + navigation | 1 week | Mostly handled by Skip scaffold |
| CI/CD for two-step build | 2–3 days | Non-trivial workflow |
| Testing + polish | 2–3 weeks | This is always underestimated |

**Rough total: 2–3 months for a production-quality Android app**

This assumes no CloudKit dependency. If the AM app uses iCloud sync, that's a separate
(non-trivial) problem — Android has no CloudKit.

---

## Comparison: Skip vs. Alternative Approaches

| Approach | Summary |
|----------|---------|
| **Skip (Fuse/native)** | Reuse SwiftUI views + business logic; real Swift runs on Android via cross-compilation. Architecture rewrite required due to TCA/PFW deps. 2–3 months. |
| **React Native** | Complete rewrite. Strong ecosystem for podcast apps. 3–5 months. |
| **Kotlin Multiplatform** | Shared business logic in Kotlin + separate native UIs. Well-established but requires learning Kotlin. 3–5 months. |
| **Flutter** | Complete rewrite. Fast iteration but non-native look. 2–4 months. |
| **Native Android (Kotlin)** | Full rewrite. Best result, most effort. 4–6 months. |

Skip's main advantage here: SwiftUI code and most non-TCA business logic can be reused directly.
The main disadvantage: the AM app is deeply TCA-coupled, eliminating much of that advantage.

---

## Recommendation

**Proceed with Skip, but with clear eyes about the scope.**

The framework itself is solid — hello world runs, audio works, SQLite works, SwiftUI renders.
The work is entirely in architectural refactoring, not in fighting Skip.

The realistic path is:
1. Refactor the AM app's architecture away from TCA **on iOS first** (using `@Observable` +
   async/await) — this is valuable work regardless of Android
2. Migrate SQLite to `skip-sql` (or abstract behind a protocol)
3. Abstract the audio layer behind a protocol with separate iOS/Android implementations
4. Add Skip Fuse as the Android build target
5. Wire up the Android audio service layer

Steps 1–3 are improvements to the iOS codebase that would be done anyway. Skip just makes
them necessary sooner.

**If the goal is an Android app in 2–3 months, Skip is the shortest path given an existing
SwiftUI codebase.** If the app is being rebuilt from scratch anyway, Kotlin Multiplatform
or React Native would give a better long-term foundation.

---

## Files in This Exploration

| File | Contents |
|------|---------|
| `exploration/research.md` | Phase 1 — Skip docs research, framework overview |
| `exploration/phase2.md` | Phase 2 — Hello world build + run on Android, two-step workflow |
| `exploration/phase3-tca-probe.md` | TCA build proof — hard blocker confirmed |
| `exploration/phase3-tca.md` | TCA theoretical analysis + workaround options |
| `exploration/phase3-sqlite.md` | GRDB probe — blocked, analysis of why |
| `exploration/phase3-skip-sql.md` | skip-sql probe — builds successfully |
| `exploration/phase3-swift-deps.md` | swift-dependencies probe — same blocker as TCA |
| `exploration/phase3-audio.md` | SkipAV probe — what works, what gaps exist |
| `exploration/summary.md` | This file |
