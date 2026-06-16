# Phase 2: Hello World / Skip Environment Setup

Date: 2026-03-21

---

## Environment Setup

### Tools Required vs Found

| Tool | Required | Found | Notes |
|------|----------|-------|-------|
| Skip CLI | 1.7.0+ | 1.7.8 ✓ | Installed from GitHub release (homebrew formula broken on current brew) |
| Swift | 5.9.0+ | 6.2.4 ✓ | Installed via swiftly |
| swiftly | 1.0.0+ | 1.1.1 ✓ | Installed from download.swift.org |
| Xcode | 15.0.0+ | 26.1.1 ✓ | Already present |
| Gradle | 8.6.0+ | 9.2.1 ✓ | Installed via homebrew |
| Java | 17.0.0+ | 25.0.1 ✓ | openjdk@17 already in homebrew; brew `skip doctor` sees java 25 from Xcode toolchain |
| Android SDK | 29.0.0+ | 33.0.0 ✓ | Already in ~/Library/Android/sdk |
| ADB | 1.0.40+ | 1.0.41 ✓ | Already present |
| Swift Android SDK | — | installing... | `skip android sdk install` |

### Installation Gotchas

1. **Homebrew skip formula is broken** — the `skiptools/skip/skip` tap fails with
   "Unexpected method 'os' called on Cask skip." This is a homebrew compatibility issue.
   Workaround: download binary directly from GitHub releases.

2. **Homebrew cask JDK installers need sudo** — both `zulu@17` and `temurin@17` cask
   installs fail without interactive sudo. Workaround: use `brew install openjdk@17`
   (formula, not cask) which installs without root.

3. **swiftly requires separate install** — not available via homebrew; must download
   from download.swift.org. Installs a full Swift 6.2.4 toolchain (~1.6GB download).

4. **`skip doctor` needs skip binary in PATH** — the binary wrapper at
   `skip.artifactbundle/bin/skip` is a shell script that calls the actual binary
   at `../macos/skip`. Must copy the whole bundle and call `bin/skip`.

5. **`skip doctor` passes all green** after installing: skip + swiftly + gradle + java
   on PATH.

---

## Hello World Project

### Creation

```bash
~/skip-bundle/bin/skip init --native-app --appid=app.gertrudeam.skiptest \
  hello-world HelloWorld
```

Result: `[✓] Skip 1.7.8 init succeeded in 61.13s`

The init resolved dependencies and built successfully in ~1 minute. This is a Skip Fuse
(native mode) project by default — `--native-app` flag confirms this.

### Generated Structure

```
hello-world/
├── Android/              ← Full Gradle project
│   ├── app/
│   │   └── build.gradle.kts
│   ├── src/              ← Kotlin entry point + resources
│   ├── settings.gradle.kts  ← Calls `skip plugin --prebuild` during Gradle init
│   └── ...
├── Darwin/               ← iOS app wrapper
│   └── Sources/Main.swift    ← @main entry point
├── Sources/
│   └── HelloWorld/
│       ├── ContentView.swift   ← Standard SwiftUI with TabView, List, Form
│       ├── HelloWorldApp.swift ← @main App struct
│       └── ViewModel.swift     ← @Observable class with JSON persistence
├── Package.swift           ← Depends on skip + skip-fuse-ui
└── Project.xcworkspace
```

### Notable Generated Code

**Package.swift:**
```swift
dependencies: [
    .package(url: "https://source.skip.tools/skip.git", from: "1.7.8"),
    .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0")
]
```

**ViewModel.swift** — uses `@Observable` (not TCA), pure Foundation:
- `@Observable public class ViewModel`
- Items stored in `URL.applicationSupportDirectory` as JSON
- Clean separation from UI

**ContentView.swift** — uses standard SwiftUI:
- `TabView`, `NavigationStack`, `List`, `Form`, `DatePicker`, `TextEditor`
- Platform-specific code example: `#if os(Android) / ComposeView { HeartComposer() }`
- `#if SKIP` blocks for raw Kotlin/Compose integration
- All very clean, idiomatic SwiftUI

**Android/settings.gradle.kts** — invokes `skip plugin --prebuild` to generate the
Kotlin/Compose bridge code during Gradle sync.

### What the Hello World Demonstrates

1. Skip Fuse projects use `@Observable` (not TCA) as the default state management pattern
2. `#if os(Android)` and `#if SKIP` are how platform-specific code is written
3. `ComposeView` + `ContentComposer` allow embedding raw Jetpack Compose inside SwiftUI
4. The iOS and Android projects are separate subdirectories in one repo
5. The build pipeline is: Swift source → skip plugin → Kotlin bridge → Gradle APK

---

## Android Build Attempt

### Key Discovery: Two-Step Build Required

**Skip Fuse native mode requires the iOS Xcode build to run FIRST to generate Kotlin bridge files.**

The skipstone SPM build tool plugin generates Kotlin bridge `.kt` files for `@bridge`-annotated types,
but ONLY when running as part of the full Xcode build pipeline, not during `skip android build` alone.

When running `skip android build` without a prior Xcode build:
- `.sourcemap` files are generated (iOS plugin runs but only partially)
- `SkipBridgeGenerated/*.swift` (JNI bridge) is generated
- **.kt Kotlin bridge files are NOT generated** → app fails to compile

### The Correct Build Workflow

```
Step 1: xcodebuild (generates Kotlin bridge files in DerivedData)
   xcodebuild -workspace Project.xcworkspace -scheme HelloWorld \
     -destination "generic/platform=iOS Simulator" \
     -skipPackagePluginValidation build

Step 2: gradle assembleDebug with BUILT_PRODUCTS_DIR set
   BUILT_PRODUCTS_DIR=<DerivedData>/Build/Products/Debug-iphonesimulator \
     gradle assembleDebug
```

The `SkipSettingsPlugin` Gradle plugin reads `BUILT_PRODUCTS_DIR` to find the
Xcode-generated plugin intermediates at `BuildToolPluginIntermediates/`.

### Kotlin Bridge Architecture (Skip Fuse Native Mode)

For a `/* SKIP @bridge */public struct HelloWorldRootView : View`, Skip generates:

**Swift side** (`SkipBridgeGenerated/HelloWorldApp_Bridge.swift`):
- JNI `@_cdecl` functions (exposed to Kotlin via JNI)
- Extension methods on `HelloWorldRootView` conforming to `BridgedToKotlin`

**Kotlin side** (`hello/world/HelloWorldApp.kt`, Xcode-generated):
```kotlin
class HelloWorldRootView: skip.ui.View, skip.bridge.SwiftPeerBridged {
    var Swift_peer: SwiftObjectPointer = SwiftObjectNil
    constructor() { Swift_peer = Swift_constructor_0() }
    private external fun Swift_constructor_0(): SwiftObjectPointer
    override fun body(): skip.ui.View { ... calls Swift via JNI ... }
}
```

### Build Results

**Step 1** (Swift → iOS compile + Kotlin gen): ~8s (after first run)
**Step 2** (Kotlin compile + APK package): 1m 54s first time
**APK size**: 121MB (debug, includes all Swift stdlib + JNI libs)
**Result**: **`BUILD SUCCESSFUL`** ✓

APK location: `.build/Android/app/outputs/apk/debug/app-debug.apk`

### Other Build Gotchas Encountered

6. **Swift 6.2.3 required for Android SDK** — swiftly installs 6.2.4 by default;
   NDK setup script needs to run from the SDK bundle location (not /tmp).

7. **NDK r27 required** — NDK r25 missing `termio` headers. Download r27d specifically.

8. **`buildAndroidSwiftPackageDebug` needs Swift sources** — The inner Gradle module's
   `src/main/swift/` was empty. Fixed by symlinking Package.swift and Sources into it.
   (This was superseded by the BUILT_PRODUCTS_DIR approach.)

---

## AVDs Available

```
4.7_WXGA_API_25
Nexus_10_API_32
Pixel_3a_API_32_arm64-v8a
Pixel_5_API_36
```

`Pixel_5_API_36` (Android 16, API 36) is the target. Skip requires Android API 28+.

---

## Emulator Run — SUCCESS ✓

Installed APK on `Pixel_5_API_36` (Android 16, API 36) emulator. App launched successfully.

### What Works
- **Welcome screen**: "Hello Skipper!" text + animated red heart ✓
- **TabView**: Welcome, Home, Settings tabs render correctly ✓
- **Swift code runs natively**: Log message from `logger.info(...)` in Swift shows in logcat ✓
- **ViewModel**: Loads 365 default items (JSON persistence works) ✓
- **Foundation APIs**: `Date.formatted()`, `URL.applicationSupportDirectory`, `JSONDecoder` all work ✓

### Logcat Evidence
```
I hello.world.HelloWorld: starting activity
D app.gertrudeam.skiptest/HelloWorld: onLaunch
I app.gertrudeam.skiptest/HelloWorld: Skip app logs are viewable in the Xcode console for iOS; Android logs can be viewed in Studio or using adb logcat
W app.gertrudeam.skiptest/HelloWorld: failed to load data from .../appdata.json, using defaultItems: ...
```

### Phase 2 Conclusion

**Skip Fuse Hello World works end-to-end on Android.** The full pipeline from SwiftUI source to
running Android app is confirmed. Key workflow insight: Xcode build is REQUIRED first to generate
Kotlin bridge files; `skip android build` alone is insufficient for native-mode packages.

---

## Next Steps

Move to Phase 3: attack the gnarliest bits for the AM app:
1. TCA / Composable Architecture — does it compile for Android at all?
2. SQLiteData / GRDB — does sqlite work on Android via Skip?
3. Audio (SkipAV) — what's actually available for podcast-style audio?
4. lib-views code sharing estimate — try porting a simple AM screen
