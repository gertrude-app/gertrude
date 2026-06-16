# Phase 1 Research: Skip Framework Feasibility for Gertrude AM

Date: 2026-03-21

---

## What is Skip?

Skip is a cross-platform Swift development framework that lets you write an app once in
Swift/SwiftUI and ship it natively on both iOS and Android. It is free, open source (LGPL
with a linking exception), and community-funded. The domain is `skip.dev` (redirected from
`skip.tools`). GitHub org: https://github.com/skiptools.

The key architectural claim: **there is no intermediary rendering engine**. iOS apps run
pure SwiftUI; Android apps run Jetpack Compose generated/bridged from the same Swift code.
iOS apps have zero runtime dependency on Skip — if Skip disappeared tomorrow, the iOS app
is untouched.

---

## The Two Modes

### Skip Lite (Transpiled Mode)

How it works: The Skip transpiler converts Swift source code into human-readable Kotlin
source, which is then compiled by the standard Kotlin compiler. Skip calls the output
style "Kotlish" — syntactically Swift, semantically Kotlin.

Every module that uses this mode needs a `Skip/skip.yml` file declaring:

```yaml
skip:
  mode: 'transpiled'
```

(This is the default if no mode is specified.)

Advantages:
- Smaller app size (only slim compatibility shims bundled)
- Faster builds (transpilation + Kotlin compile beats native compile)
- Full transparency: generated Kotlin is human-readable and editable
- Direct Kotlin/Java API access with no bridging overhead
- Ejectability: if you drop Skip, you have full source for both iOS and Android

Disadvantages:
- Not all Swift language features can map to Kotlin
- Limited standard library coverage (SkipLib/SkipFoundation replicate only a subset)
- Almost no third-party Swift packages work unless they are "Skip-aware" (i.e., have their
  own `Skip/skip.yml` and transpiled implementations)
- JVM GC, no Swift value-type performance benefits
- `#if DEBUG` always resolves to false on Android
- C/C++ native integration is awkward (requires SkipFFI)

### Skip Fuse (Native/Compiled Mode)

How it works: Uses the Swift SDK for Android (now an officially supported Swift platform
as of October 2025, coming in Swift 6.3) to cross-compile Swift directly to native Android
shared libraries (.so files). The resulting native Swift code is packaged into the APK
alongside standard Kotlin/Compose code. JNI bridging code is auto-generated to allow
Swift and Kotlin to call each other.

Mode declaration in `skip.yml`:

```yaml
skip:
  mode: 'native'
```

Advantages:
- Full Swift language support — no feature gaps from transpilation
- Access to thousands of pure Swift packages that compile for Android
- True Swift value types and memory model (stack allocation, deterministic dealloc)
- C/C++ integration works naturally (same as on iOS)
- Direct access to `@Observable`, async/await, Swift concurrency — all work as designed
- No vendor lock-in concern: the underlying Swift SDK for Android is now officially
  maintained by the Swift project itself

Disadvantages:
- Larger app size: embeds Swift standard library (~60MB: `libSwiftCore.so`,
  `libSwiftFoundation.so`, `lib_FoundationICU.so` alone is ~40MB)
- Slower build times: Swift must compile twice (once for iOS, once for Android)
- Debugging native code on Android is harder than debugging generated Kotlin
- Cannot use binary SPM dependencies (SPM limitation — source-only)
- Bridging between Swift and Kotlin has some overhead for data crossing the boundary

### Which is Recommended?

**Skip Fuse (native) is the recommended approach for most apps.** Skip's own documentation
says: "most developers will choose to use native mode where possible." The language
completeness and access to the existing Swift package ecosystem are decisive advantages.

The hybrid pattern is common in practice: a Skip Fuse app for the main app modules, with
specific Skip Lite modules for anything that needs tight Kotlin/Java API integration (e.g.,
a module wrapping a specific Android SDK).

---

## Architecture: How Swift Compiles to Android

In Skip Fuse mode:

1. Your Swift package has a `Skip/skip.yml` declaring `mode: 'native'`
2. The Skip Xcode/SPM plugin runs during build, invoking the Skip toolchain
3. The Swift cross-compilation toolchain (Swift SDK for Android) compiles your Swift to
   ARM64/x86_64 Android native libraries
4. The plugin auto-generates JNI bridging code (`// SKIP @bridge` annotations mark APIs
   for exposure)
5. SkipFuseUI bridges your SwiftUI views to Jetpack Compose via SkipUI
6. Everything is packaged into an APK

For SwiftUI specifically: SkipFuseUI (a native Swift package) wraps SkipUI (a Kotlin
reimplementation of SwiftUI for Jetpack Compose). The `@Observable` property wrapper is
bridged so Swift observables drive Compose UI reactivity.

Build performance benchmark (M1 MacBook Pro):
- Transpiled (Lite): ~10 seconds total (7s Gradle)
- Native (Fuse): ~21 seconds total (15s Gradle + ~8s for Swift compile + bridge generation)

---

## Package Requirements

To add Skip to a Swift package:

1. Install Skip CLI: `brew install skiptools/skip/skip`
2. Add the Skip plugin to `Package.swift`:
   ```swift
   .package(url: "https://source.skip.dev/skip.git", from: "1.0.0")
   ```
3. Add a `Skip/skip.yml` in each module target directory
4. For Skip Fuse apps, depend on `SkipFuse` and `SkipFuseUI`:
   ```swift
   .package(url: "https://source.skip.dev/skip-fuse.git", from: "1.0.0")
   .package(url: "https://source.skip.dev/skip-fuse-ui.git", from: "1.0.0")
   ```

System requirements:
- macOS 15+
- Xcode (latest)
- Android Studio
- Swift 5.9.0+
- Gradle 8.6.0+
- Java 17.0.0+
- Android: minimum API 28, target API 34
- iOS: minimum iOS 16+

First build downloads ~1GB of Compose/Gradle dependencies.

---

## SwiftUI Feature Support (SkipUI)

SkipUI is a Kotlin reimplementation of SwiftUI for Jetpack Compose. It covers a large
portion of SwiftUI but has gaps.

Well supported:
- State management: `@State`, `@StateObject`, `@Binding`, `@Environment`,
  `@EnvironmentObject`, `@Observable` (via SkipModel)
- Layout: `HStack`, `VStack`, `ZStack`, `ScrollView`, `GeometryReader`, `.frame`
- Common views: `Text`, `Button`, `Image`, `AsyncImage`, `TextField`, `SecureField`,
  `Picker`, `Toggle`, `List`, `Form`, `NavigationStack`, `TabView`, `Menu`
- Styling: colors, fonts, gradients, shadows, borders, `.foregroundStyle`, `.background`,
  `.padding`, `.opacity`, animation/transition modifiers
- Gestures: tap, long-press, drag, magnify, rotate (with some customization limits)

Partially supported / limitations:
- `DatePicker` works but date range constraints require Skip Fuse bridging
- `@GestureState` only in Skip Fuse, not Skip Lite
- `@AppStorage` doesn't support optional values
- Grid pinned headers/footers unsupported
- Advanced table features (multiple selection) unsupported

Not supported:
- Custom `Animatable` and custom `Transition`
- `@FocusState.Binding`
- `contextMenu`
- Extensive UIKit integration
- `#if DEBUG` in Skip Lite always false on Android

Workarounds:
- `ComposeView` to embed raw Jetpack Compose code inside SwiftUI views
- `.material3` modifier for Android-specific Material Design customization
- `#if SKIP` conditional compilation blocks for platform-specific code
- `AnyDynamicObject` for calling Kotlin/Java APIs from native Swift with zero setup

---

## AM App Architecture Overview

The Gertrude AM app is an iOS podcast player with parental controls. It lives in
`swift/podcasts/` with three packages:

### lib-core
- Platform stubs only (allows macOS compilation for testing)
- No external dependencies

### lib-views
- All SwiftUI views
- Depends on: lib-core, swift-custom-dump (test only)
- Pure SwiftUI — no TCA, no database

### lib-tca
- All app logic, reducers, dependencies
- Depends on: lib-core, lib-views, pairql-podcasts, and these Point-Free libraries:
  - `sqlite-data` (v1.4.0) — the PFW SQLite ORM
  - `swift-dependencies` (v1.10.0+) — dependency injection
  - `swift-composable-architecture` (v1.25.0+) — TCA
  - `swift-custom-dump` (v1.3.3+) — testing assertions
  - `swift-tagged` (v0.10.0+) — type-safe IDs
  - `swift-structured-queries` (v0.25.2) — query builder (used with SQLiteData)

Key features / dependencies in the app:
- SQLite database via `sqlite-data` + `swift-structured-queries` (custom PFW query builder)
- Audio playback via `AVPlayer`, `AVAudioSession`, `MediaPlayer` (MPRemoteCommandCenter,
  MPNowPlayingInfoCenter — lock screen controls)
- StoreKit for subscription management
- Background tasks (`BGTaskScheduler`)
- Keychain
- Network requests (podcast RSS feed fetching)
- Background audio downloading (`URLSession`)

---

## Point-Free Library Compatibility Assessment

### The Composable Architecture (TCA) — HIGH RISK

TCA (v1.25.0 in use here) heavily uses Swift macros (`@Reducer`, `@ObservableState`,
`@Presents`, `@Shared`, `@Fetch`, `@DependencyClient`, `@DependencyEndpoint`). Swift
macros require `swift-syntax`, which itself needs to compile a macro plugin binary for
the host machine.

**The core problem:** TCA has never claimed Android support. Its `Package.swift` only
declares Apple platforms (iOS, macOS, watchOS, tvOS, visionOS). The Swift Package Index
does not show Android as a supported platform for TCA.

**In Skip Fuse mode:** Native compilation compiles Swift to Android libraries, so
*theoretically* pure Swift code that uses TCA types could compile. However:
- Swift macros in SPM only expand during compilation on the host machine; the expanded
  code compiles for Android. So macros themselves aren't the blocker.
- The TCA library itself imports `SwiftUI`, `Combine`, and iOS-specific frameworks that
  don't exist on Android (or exist only partially through Skip's shims)
- TCA uses `@Observable` (requires SkipModel bridge), `Combine.Publisher` (SkipFoundation
  has partial coverage), and deep SwiftUI integration

**Likely outcome:** TCA will NOT compile for Android without modification. It imports
platform-specific frameworks and has not been designed for Android. This is probably the
single biggest blocker for a direct port.

**Mitigation options:**
1. Wrap all TCA reducers/state behind `#if !os(Android)` and write Android-specific
   state management (defeats much of the purpose of Skip)
2. Use `@Observable` directly (without TCA) on Android — a significant architectural
   rewrite
3. Contribute Android support to TCA (enormous effort; unlikely to land quickly)
4. Use Skip Fuse only for non-TCA modules (lib-views, lib-core), with the Android side
   having its own ViewModel layer

### sqlite-data (PFW SQLiteData) — MEDIUM-HIGH RISK

`sqlite-data` is PFW's SQLite ORM. It uses `GRDB`-style concepts but is PFW's own
implementation with `swift-structured-queries` as the query layer.

**Note:** This is NOT the same as Skip's `SkipSQL`. Skip provides its own SQLite module
(SkipSQL) which directly uses the SQLite C API on both platforms. It has its own
`SQLCodable` protocol and migration system.

The app uses `sqlite-data` with `swift-structured-queries` (also PFW, v0.25.2). These
packages declare only Apple platforms. The `@Table` macro and query DSL (`Episode.where`,
`.update`, `.delete`, `.returning`) is PFW-specific.

**In Skip Fuse mode:** sqlite-data would need to compile for Android. It likely uses
Foundation types (Date, URL, etc.) which Skip provides via SkipFoundation, but it also
likely uses OS-level SQLite C APIs. Whether it compiles for Android is untested —
sqlite-data has no declared Android support.

**Likely outcome:** sqlite-data will probably NOT compile for Android out of the box,
since it's Apple-platform-only. A port approach would be: replace sqlite-data with
SkipSQL on Android using `#if os(Android)` conditionals, which means maintaining two
database layers.

### swift-dependencies — LOW-MEDIUM RISK

`swift-dependencies` is the dependency injection library. It uses Swift macros
(`@DependencyClient`, `@DependencyEndpoint`) and relies on Foundation and Swift standard
library. It has been noted on the Swift Package Index as one of the PFW packages that
*does* compile for Android in some configurations (`swift-custom-dump` appeared in a
search of iOS+Android compatible packages).

**Likely outcome:** swift-dependencies *might* compile for Android in Skip Fuse mode
since it's relatively pure Swift. However, many dependency keys in the AM app inject
iOS-specific types (AVPlayer, AVAudioSession, MPRemoteCommandCenter, etc.), which would
still need `#if !os(Android)` guards.

### swift-tagged — LOW RISK

Very simple type-level wrapper. Uses Swift generics and protocols only. Almost certainly
compiles for Android in Skip Fuse mode.

### swift-custom-dump — LOW RISK

Used only in tests. Skip provides SkipUnit (XCTest-to-JUnit bridge), so tests may work.
swift-custom-dump appeared in searches of packages with iOS+Android compatibility.

### swift-structured-queries — UNKNOWN RISK

This is a newer PFW library (used with sqlite-data). It generates query DSL through
macros (`@Table`). No information found about Android compatibility. Tied closely to
sqlite-data — if sqlite-data doesn't work, this doesn't matter.

---

## Audio Playback Assessment

The AM app uses:
- `AVPlayer` for local file playback (downloaded episodes)
- `AVAudioSession` for audio session configuration (`.playback` category, `.spokenAudio`
  mode)
- `MPRemoteCommandCenter` for lock screen controls (play, pause, skip forward/back, scrub)
- `MPNowPlayingInfoCenter` for "now playing" metadata on lock screen
- `CMTime` for time operations
- `Combine.Publisher` for streaming system events (play, pause, scrub, interruption)
- `NotificationCenter` for `AVPlayerItemDidPlayToEndTime` and
  `AVAudioSession.interruptionNotification`

Skip's SkipAV provides:
- `AVAudioPlayer` — high support
- `AVAudioRecorder` — high support
- `AVPlayer` — **low support** (only `init`, `play()`, `pause()`, `seek(to:)`)
- No coverage of `AVAudioSession`, `MPRemoteCommandCenter`, or `MPNowPlayingInfoCenter`

**Assessment:** The audio layer is a major gap. The AM app's use of `AVPlayer` is in the
"low support" category, and it relies heavily on `MPRemoteCommandCenter` (lock screen
controls) and `AVAudioSession` (interruption handling) which have NO Skip equivalents.
Android equivalents exist (MediaSession, ExoPlayer from androidx.media3, AudioManager)
but require a completely new platform-specific implementation.

**This is the second-biggest blocker after TCA.** The audio dependency would need a
full abstraction layer with separate iOS and Android implementations.

---

## Other Platform-Specific Concerns

### StoreKit
- No Skip equivalent. Android equivalent is Google Play Billing.
- Would need `#if !os(Android)` with Android-specific in-app purchase code.
- The subscription model itself would work (it's just data), but the purchase flow is
  platform-specific.

### Background Tasks (BGTaskScheduler)
- iOS-specific. Android has WorkManager.
- Would need platform-specific implementations.

### Keychain
- Skip has a `SkipKeychain` integration framework in its ecosystem.
- Likely solvable.

### Network / RSS Parsing
- URLSession works via SkipFoundation.
- XML parsing (the app has an XML dependency) — SkipFoundation has partial Foundation
  coverage; `XMLParser` availability unclear.

### UIKit dependencies
- The views use `UIImage` (`show.localArtworkImage ?? UIImage(named: "artwork")`,
  `.mediaItemArtwork`). SkipUI does not provide UIKit integration.

---

## Summary: Key Blockers for Direct Port

In roughly descending order of severity:

1. **TCA (Composable Architecture)** — Apple-platform-only, deeply integrated with
   SwiftUI internals. Would not compile for Android. The entire app logic layer is TCA.

2. **Audio Layer** — AVPlayer support is minimal in SkipAV. AVAudioSession,
   MPRemoteCommandCenter, MPNowPlayingInfoCenter have no Skip equivalents. A podcast
   player without lock screen controls is a non-starter on Android.

3. **sqlite-data / swift-structured-queries** — PFW's SQLite stack is Apple-only.
   Would need replacement with SkipSQL + a new query layer on Android.

4. **StoreKit** — Would need separate Android in-app billing implementation.

5. **Background task infrastructure** — BGTaskScheduler is iOS-only.

6. **UIKit references** in views (UIImage, media artwork) — minor but present.

---

## What CAN Work Without Changes (or Easily)

- **lib-views (SwiftUI views):** The views in lib-views are fairly clean SwiftUI with no
  TCA dependencies. Most use standard SwiftUI components (List, NavigationStack, Text,
  Button, VStack, HStack, etc.). This is the most promising candidate for Skip Fuse
  direct use. Some custom animations and gestures may need attention.

- **lib-core:** Pure Swift, no dependencies. Would compile trivially.

- **Data models (Episode, Show, etc.):** Pure Swift structs. Would compile fine, though
  the `@Table` macro from swift-structured-queries may not expand correctly on Android.

- **swift-dependencies DI system:** Likely mostly works in Skip Fuse. The injected
  *implementations* need platform conditionals, but the DI framework itself is lightweight.

- **swift-tagged:** Trivially cross-platform.

- **Network layer:** URLSession calls through SkipFoundation should work.

---

## Recommended Architecture for Android Port

Given these findings, the viable path is NOT a direct shared-code approach for the whole
app. Instead, a layered approach:

```
iOS-only layer:
  - TCA reducers (or replace with @Observable ViewModels for Android)
  - Audio: AVPlayer + AVAudioSession + MPRemoteCommandCenter
  - StoreKit
  - Background tasks

Shared layer (via Skip Fuse):
  - lib-views (SwiftUI views, with platform conditionals for UIKit refs)
  - lib-core (platform stubs)
  - Data models (structs, no macro magic)
  - Network client (URLSession)

Android-specific layer:
  - ViewModel / state management (replaces TCA)
  - Audio: ExoPlayer + MediaSession (via SkipAV + direct Compose bridging)
  - Google Play Billing
  - WorkManager for background sync
  - SkipSQL for database
```

The views layer is genuinely shareable (~60-70% of view code). The business logic
(reducers) would need a redesign or two-track approach.

---

## Effort Estimate (Rough)

| Component | Effort | Notes |
|---|---|---|
| Skip Fuse setup + Hello World | 1-2 days | Well-documented |
| lib-views working in Skip Fuse | 3-5 days | SwiftUI gaps, UIKit refs |
| Audio layer (Android replacement) | 1-2 weeks | Entirely new implementation |
| TCA replacement on Android | 2-4 weeks | Major architectural work |
| Database (SkipSQL migration) | 1 week | Parallel DB layers |
| StoreKit → Play Billing | 1-2 weeks | Separate purchase flows |
| Background sync (WorkManager) | 3-5 days | |
| Integration + polish | 2-4 weeks | Long tail of platform differences |
| **Total estimate** | **2-4 months** | For a production-ready Android app |

---

## Open Questions for Phase 2+

1. Does TCA actually fail to compile with the Swift SDK for Android? (Need to try)
2. Does swift-dependencies compile for Android? (Likely yes — test it)
3. Do the SwiftUI views in lib-views compile and render correctly in Skip Fuse?
4. What is the exact SkipAV support for streaming audio (vs downloaded files)?
5. Is there a way to use ExoPlayer through `AnyDynamicObject` without a full Lite module?
6. Does `#if SKIP` work in a Skip Fuse module, or only in Lite?

---

## Sources

- https://skip.dev/docs/modes/ (Lite vs Fuse comparison)
- https://skip.dev/docs/gettingstarted/ (setup and requirements)
- https://skip.dev/docs/dependencies/ (package dependency system)
- https://skip.dev/docs/modules/skip-ui/ (SwiftUI support)
- https://skip.dev/docs/modules/skip-av/ (audio/video support)
- https://skip.dev/docs/faq/ (limitations, FAQ)
- https://skip.dev/blog/official-swift-sdk-for-android/ (Swift SDK status)
- https://github.com/skiptools/skip-fuse (SkipFuse README)
- https://github.com/skiptools/skip-ui (SkipUI README)
- https://forums.swift.org/t/building-apps-with-skips-native-swift-android-toolchain-integration-tech-preview/76365 (build performance data)
