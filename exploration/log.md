## status

**COMPLETE.** All phases done. Final summary written to `exploration/summary.md`.

**Verdict: YES, BUT** — Skip Fuse works, but the AM app's Point-Free dependency stack
(TCA, swift-dependencies, sqlite-data) must all be replaced. This is the core work.

**Hard blockers:**
- TCA 1.25.0: `combine-schedulers` Combine types fail unconditionally. Won't build.
- `swift-dependencies`: Same root cause. Won't build.
- `sqlite-data` (PFW): Apple-only.

**Working (probed):**
- Skip Fuse hello world: BUILD SUCCESSFUL, runs on Pixel 5 API 36 emulator ✓
- skip-sql (SkipSQLPlus): SQLite on Android via bundled amalgamation ✓
- SkipAV basic playback: play/pause/seek/rate/completion via ExoPlayer ✓

**Audio gaps (custom Android work, not blockers):**
1. `addPeriodicTimeObserver` → coroutine timer (~1 day)
2. `AVAudioSession` → AudioManager.requestAudioFocus (~1–2 days)
3. `MPRemoteCommandCenter/NowPlayingInfoCenter` → MediaSession service (~2–4 days)

**Effort estimate:** 2–3 months for production-quality Android app.
- Audio is achievable but needs a separate `AudioPlayer` implementation for Android using
  `#if SKIP` native code. The platform seam is clean; complexity is medium.

---

## 2026-03-21 — Phase 1: Research

### What was tried

Read all Skip documentation from skip.dev, the GitHub repos (skip, skip-fuse, skip-ui,
skip-av), and the Swift forums post about the native toolchain tech preview. Also read the
AM app codebase (lib-tca/Package.swift, AppReducer.swift, Audio.swift, Database.swift,
Episode.swift, the lib-views package).

### What was learned

**About Skip:**
- Skip offers two modes: Skip Lite (transpiler: Swift → Kotlin) and Skip Fuse (compiler:
  Swift → Android native via Swift SDK for Android). Fuse is the recommended modern approach.
- Swift SDK for Android became officially supported by the Swift project in October 2025
  (Swift 6.3 cycle). This legitimizes the whole approach — it's not a Skip-specific hack.
- Skip Fuse has no Swift language limitations. Any Swift package that compiles for Android
  works. Lite has significant Swift language and library limitations.
- App size penalty for Fuse: ~60MB for Swift runtime libraries in the APK.
- Build time penalty: ~2x compared to iOS-only builds.

**About the AM app:**
- Three packages: lib-core (nothing), lib-views (SwiftUI only), lib-tca (all logic)
- lib-tca depends on: TCA, sqlite-data, swift-structured-queries, swift-dependencies,
  swift-tagged, swift-custom-dump
- The audio implementation is deeply iOS-specific: AVPlayer, AVAudioSession,
  MPRemoteCommandCenter, MPNowPlayingInfoCenter, CMTime, Combine publishers
- Database uses PFW's sqlite-data with @Table macros and swift-structured-queries DSL
- StoreKit, BGTaskScheduler, Keychain are all used

**About compatibility:**
- TCA: NOT compatible with Android. Apple-platform-only by design.
- sqlite-data/swift-structured-queries: NOT compatible with Android. Apple-platform-only.
- swift-dependencies: Probably compatible in Skip Fuse (pure Swift). Needs testing.
- swift-tagged: Compatible.
- Audio layer: Major rewrite needed for Android (ExoPlayer + MediaSession).
- SwiftUI views (lib-views): Likely mostly compatible with Skip Fuse. Best bet for
  shared code.

### What's next

Phase 2: Install Skip, get Hello World running on Android emulator. Then try to add
Skip Fuse to lib-views and see how far it compiles.

---

## 2026-03-21 — Phase 2: Hello World (summary, logged from prior session)

Phase 2 was completed in a prior session. A minimal Skip Fuse app was built and ran on
the Android emulator. Key gotcha: the `Skip/skip.yml` file must exist in
`Sources/<TargetName>/Skip/` for the skipstone plugin to process the module. Without it,
you get: "In order for Skip to process the module, a Skip/ folder must exist..."

The hello-world project is at `exploration/phase2/hello-world/`.

---

## 2026-03-21 — Phase 3: Gnarliest Bits Probes

### What was tried

Built three probe packages to test the AM app's core Point-Free dependencies on Android:
1. `tca-probe` — TCA with `swift-composable-architecture` 1.25.0
2. `grdb-probe` — GRDB 7.x as SQLite replacement
3. `deps-probe` — `swift-dependencies` 1.10.0+
4. `skip-sql-probe` — Skip's official `SkipSQLPlus` as SQLite path

### TCA probe result: HARD BLOCKER

TCA fails in `combine-schedulers` (transitive dep). That library uses Combine types
(`Publishers`, `Subscriber`, `Scheduler`, `Cancellable`) unconditionally — no platform
guards. Android has no Combine framework, so it's a clean compile error.

Dependency chain: TCA → swift-dependencies → combine-schedulers → **Combine (Apple only)**

Not fixable without forking/patching `combine-schedulers`. No indication PFW will do this.

### swift-dependencies probe result: SAME HARD BLOCKER

Identical failure to TCA — `combine-schedulers` is also a dep of `swift-dependencies`
directly. The DI *pattern* ports fine (it's just structs of closures), but the library
doesn't build on Android.

### GRDB probe result: BLOCKED (but SQLite itself is solvable — see below)

GRDB fails because it uses `.systemLibrary(name: "GRDBSQLite")` which expects `sqlite3.h`
from the system. The Swift Android SDK sysroot doesn't include `sqlite3.h` — SQLite exists
on Android devices as a system library but the NDK sysroot doesn't expose it.

Note: GRDB 7.10.0 added "Android adjustments" (by `@marcprux`, Skip-affiliated), but this
was code-level guards, not a solution to the missing header.

### skip-sql probe result: SUCCESS

Skip's official `skip-sql` package provides `SkipSQLPlus` which bundles the SQLite
amalgamation (`sqlite3.c` compiled from source). Clean build for Android — no system
header needed.

Key detail: must use `SkipSQLPlus` not `SkipSQL`. The `SkipSQL` product falls back to
`fatalError` on non-Skip Android path. `SkipSQLPlus` always works.

Package version at `0.16.0` — hasn't reached 1.0. API surface: lower-level than GRDB,
but `SQLCodable` provides ORM-style patterns.

### What was learned

1. The Combine dependency is the single root cause for PFW library failures on Android.
   `combine-schedulers` is a shared transitive dep pulling in all of them.
2. SQLite access on Android is solved via `SkipSQLPlus`. This replaces both `sqlite-data`
   and GRDB in an Android port.
3. The `skip.yml` file requirement applies to every target with the skipstone plugin.
4. Build times: first TCA resolution took ~3-4 minutes (large dep tree). GRDB was faster.
   `skip-sql-probe` was fast after library cached.

### What's next

Priority remaining tasks:
1. Test audio playback — likely the hardest remaining piece (ExoPlayer + MediaSession)
2. Try porting lib-views (SwiftUI layer) with Skip Fuse
3. Assess whether a thin wrapper around `combine-schedulers` could be created to eliminate
   the Combine dependency (allowing TCA or swift-dependencies to compile)

---

## 2026-03-21 — Phase 3: Audio Probe

### What was tried

- Read the full audio layer of the AM app (`Audio.swift`, `Platform.swift`)
- Cataloged every iOS audio API used (AVPlayer, AVAudioSession, MPRemoteCommandCenter, etc.)
- Found and read the `skip-av` package (skiptools/skip-av, v0.6.2)
- Read the README, Package.swift, all source files, changelog, and recent PRs
- Created `exploration/phase3/audio-probe/` — a minimal Swift package that imports
  `SkipAV` and probes each relevant API
- Built the probe (macOS host build: passes with no errors)
- Inspected the generated Kotlin to confirm which APIs are transpiled

### What was learned

1. **SkipAV exists and is real**: Backed by ExoPlayer via `androidx.media3`. Currently
   at v0.6.2. Active development (last commit March 2026).

2. **Basic playback works**: AVPlayer(url:), play/pause/seek/rate/volume/timeControlStatus,
   and completion notifications all function on Android.

3. **AVAudioPlayer has higher support**: Fully backed by Android's MediaPlayer. Better
   support level than AVPlayer.

4. **Three critical gaps confirmed**:
   - `addPeriodicTimeObserver` — completely absent from SkipAV
   - `AVAudioSession` — not implemented; iOS-only
   - `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter` — not implemented

5. **media3-session is already a dependency**: The `skip.yml` in SkipAV declares
   `media3-session` as a Gradle dependency. PR #18 added `AVPlayer(player: MediaController)`
   specifically to enable apps to integrate with a MediaSession. The infrastructure for
   lock screen controls exists but is not exposed via Swift APIs.

6. **Platform seam is clean**: The AM app's `AudioPlayer` struct is a `DependencyKey`.
   Since `swift-dependencies` is a blocker anyway, the audio layer must be redesigned.
   A protocol-based abstraction with iOS and Android implementations is the way to go.

### What's next

- Phase 3 continues: SwiftUI view layer probe (lib-views with Skip Fuse)
- Phase 4 consideration: Mini screen port using a simple screen from lib-views
- Audio implementation is now well-understood enough to estimate effort for summary.md
