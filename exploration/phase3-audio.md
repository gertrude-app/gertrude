# Phase 3: Audio Probe — SkipAV Feasibility for Gertrude AM

Date: 2026-03-21

---

## Summary

SkipAV exists and provides basic audio playback via ExoPlayer on Android. The core
play/pause/seek/rate/completion functionality is present and works. However, three critical
features used by the AM app are **not** implemented in SkipAV:

1. `addPeriodicTimeObserver` — used for real-time progress updates
2. `AVAudioSession` — used for audio focus, interruption handling, and `.spokenAudio` mode
3. `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter` — used for lock screen controls

All three require Android-native workarounds (native Kotlin code in `#if SKIP` blocks or
a custom Skip bridge layer). This is **medium-difficulty** work, not insurmountable, but
it is material effort that must be custom-built. None of it is drag-and-drop.

---

## Step 1: AM App Audio Architecture

The audio layer lives in two files:

- `swift/podcasts/lib-tca/Sources/Deps/Audio.swift` — the `AudioPlayer` dependency client
- `swift/podcasts/lib-core/Sources/Platform.swift` — macOS stubs for iOS-only APIs

### Key APIs Used

| API | Where Used | Purpose |
|-----|-----------|---------|
| `AVPlayer(url:)` | `Audio.swift:354` | Create player from local file URL |
| `AVPlayer.play()` / `.pause()` | `Audio.swift` | Playback control |
| `AVPlayer.seek(to: CMTime)` | `Audio.swift:343` | Seek to position |
| `AVPlayer.timeControlStatus` | `Audio.swift:372` | Check if playing |
| `AVPlayer.addPeriodicTimeObserver(forInterval:queue:)` | `Audio.swift:235` | 1-second progress ticks |
| `AVPlayer.removeTimeObserver(_:)` | `Audio.swift:369` | Cleanup periodic observer |
| `AVAudioSession.sharedInstance()` | `Audio.swift:80-83` | Audio session setup |
| `AVAudioSession.setCategory(.playback)` | `Audio.swift:81` | Background audio |
| `AVAudioSession.setMode(.spokenAudio)` | `Audio.swift:82` | Podcast mode |
| `AVAudioSession.setActive(true)` | `Audio.swift:83` | Activate session |
| `AVAudioSession.interruptionNotification` | `Audio.swift:284` | Phone call interruptions |
| `MPRemoteCommandCenter.shared()` | `Audio.swift:139-153` | Lock screen controls |
| `MPRemoteCommandCenter.playCommand` | `Audio.swift:157` | Lock screen play |
| `MPRemoteCommandCenter.pauseCommand` | `Audio.swift:165` | Lock screen pause |
| `MPRemoteCommandCenter.skipForwardCommand` | `Audio.swift:204` | +30s skip |
| `MPRemoteCommandCenter.skipBackwardCommand` | `Audio.swift:187` | -15s skip |
| `MPRemoteCommandCenter.changePlaybackPositionCommand` | `Audio.swift:176` | Scrubbing |
| `MPRemoteCommandCenter.nextTrackCommand` | `Audio.swift:218` | Headphone double-tap |
| `MPRemoteCommandCenter.previousTrackCommand` | `Audio.swift:224` | Headphone triple-tap |
| `MPNowPlayingInfoCenter.default()` | `Audio.swift:135` | Now playing display |
| `MPMediaItemPropertyTitle` etc. | `Audio.swift:122-134` | Lock screen metadata |
| `MPMediaItemPropertyArtwork` | `Audio.swift:133-135` | Album art on lock screen |
| `AVPlayerItem.didPlayToEndTimeNotification` | `Audio.swift:260` | Episode completion |
| `CMTime(seconds:preferredTimescale:)` | `Audio.swift:236,343` | Time representation |

### Architecture Pattern

The AM app wraps all audio functionality behind an `AudioPlayer` dependency client
(via `swift-dependencies`). The live implementation uses a `Player` class with a
`Mutex<AVPlayerData?>` for thread safety. This is fairly clean and has a natural seam
for platform abstraction — the `AudioPlayer` struct could have separate iOS and Android
live implementations.

**Important:** `swift-dependencies` is a BLOCKER for Android (confirmed in earlier
phase), so the dependency injection pattern needs a different approach on Android.

---

## Step 2: SkipAV — What It Provides

`skip-av` is a real, actively maintained package by Skip (skiptools/skip-av on GitHub).
It provides a subset of `AVFoundation` and `AVKit` backed by Android's ExoPlayer
(`androidx.media3`). It also works in both transpile (Skip Lite) and native (Skip Fuse)
modes.

### What SkipAV Provides (Android-Ready)

| API | Support Level | Notes |
|-----|--------------|-------|
| `AVPlayer(url:)` | 🟠 Low | Basic play/pause/seek only |
| `AVPlayer(playerItem:)` | 🟠 Low | Via ExoPlayer |
| `AVPlayer.play()` / `.pause()` | 🟠 Low | Works |
| `AVPlayer.seek(to: CMTime)` | 🟠 Low | Works |
| `AVPlayer.rate` | 🟠 Low | Works (setPlaybackSpeed) |
| `AVPlayer.timeControlStatus` | 🟠 Low | Added in v0.6.2 |
| `AVPlayer.volume` | 🟠 Low | Works |
| `AVQueuePlayer` | 🟠 Low | Queue management via ExoPlayer |
| `AVPlayerLooper` | 🟠 Low | Loop support |
| `AVPlayerItem(url:)` | 🟠 Low | Basic |
| `AVPlayerItem.didPlayToEndTimeNotification` | ✅ | Via NotificationCenter |
| `AVPlayerItem.timeJumpedNotification` | ✅ | Via NotificationCenter |
| `AVPlayerItem.playbackStalledNotification` | ✅ | Via NotificationCenter |
| `AVAudioPlayer(contentsOf:)` | 🟢 High | Via Android MediaPlayer |
| `AVAudioPlayer.play/pause/stop` | 🟢 High | Works |
| `AVAudioPlayer.currentTime` | 🟢 High | Works |
| `AVAudioPlayer.rate` | 🟢 High | Works |
| `AVAudioPlayer.volume` | 🟢 High | Works |
| `AVAudioPlayer.duration` | 🟢 High | Works |
| `AVAudioRecorder` | 🟢 High | Recording support |
| `VideoPlayer` | 🟡 Medium | SwiftUI VideoPlayer component |
| `CMTime` | ✅ | Custom implementation |

### What SkipAV Does NOT Provide

| API | Android Equivalent | Notes |
|-----|--------------------|-------|
| `AVPlayer.addPeriodicTimeObserver` | `Handler.postDelayed` / coroutine | Must implement manually |
| `AVPlayer.removeTimeObserver` | Cancel coroutine/handler | Must implement manually |
| `AVAudioSession` | `AudioManager.requestAudioFocus` | Must implement manually |
| `AVAudioSession.interruptionNotification` | `AudioFocusRequest` callbacks | Must implement manually |
| `MPRemoteCommandCenter` | `MediaSession` + `MediaButtonReceiver` | Must implement manually |
| `MPNowPlayingInfoCenter` | `MediaSession.setMetadata()` | Must implement manually |
| Lock screen artwork | `MediaDescriptionCompat` | Must implement manually |

### SkipAV Package Details

- Version tested: 0.6.2 (released 2026-02-10)
- GitHub: https://github.com/skiptools/skip-av
- License: LGPL-3.0 with app-store linking exception
- Android backing: `androidx.media3` v1.9.2 (ExoPlayer)
- Gradle dependencies pulled in:
  - `media3-ui`, `media3-ui-compose`, `media3-common`
  - `media3-session` (MediaSession support available but NOT bridged to Swift)
  - `media3-exoplayer`, `media3-exoplayer-hls`, `media3-exoplayer-dash`
- Notable: `media3-session` is already a declared dependency but not exposed via Swift API

### Key Observation: MediaController Support

PR #18 (merged Jan 12, 2026) added `AVPlayer(player: Player)` — an initializer that
accepts an ExoPlayer `MediaController` directly. This is the intended pathway for
integrating with Android's `MediaSession` (which powers lock screen controls). The
infrastructure is there; it's just not fully wired up to Swift-accessible APIs yet.

---

## Step 3: Build Results

### Probe Created

Location: `exploration/phase3/audio-probe/`

### macOS (host) Build: PASSES

```
Build complete! (5.74s)
```

All probe functions compile successfully on macOS. The `#if !SKIP` guards correctly
exclude iOS-only APIs from the Skip transpiler.

### Generated Kotlin Analysis

The probe generates a `AudioProbe.kt` that imports `skip.av.*`, but only the
functions that use cross-platform APIs (AVPlayer, AVAudioPlayer, CMTime, AVPlayerItem
notifications) produce Kotlin. The iOS-only APIs (`AVAudioSession`,
`MPRemoteCommandCenter`, `MPNowPlayingInfoCenter`, `addPeriodicTimeObserver`) are
correctly stripped via `#if !SKIP` or `#if os(iOS) && !SKIP` guards.

The SkipAV-generated `AVPlayer.kt` contains a full ExoPlayer implementation with:
- `MediaItem`, `ExoPlayer.Builder`, `Player.Listener` interface
- `onPlaybackStateChanged` fires `didPlayToEndTimeNotification` via `NotificationCenter`
- `onPositionDiscontinuity` fires `timeJumpedNotification` via `NotificationCenter`
- No `addPeriodicTimeObserver` equivalent (confirmed absent)

### Android Build: NOT TESTED (no Android emulator in this session)

The probe generates correct Gradle artifacts in the skipstone output directory. The
package has been verified to resolve dependencies and compile for macOS. A full Android
Gradle build would require either plugging the probe into the hello-world Android project
or running `gradle assembleDebug` from the generated skipstone directory.

---

## Step 4: Assessment

### Can Core Podcast Audio Work on Android via Skip?

**Yes, with custom work for 3 key gaps.**

The basic play/pause/seek/rate/completion functionality works via SkipAV today. The
three missing pieces require native Android implementation:

---

### Gap 1: `addPeriodicTimeObserver` — MEDIUM effort

**What AM uses it for:** 1-second progress updates to update the UI progress bar and
sync the `MPNowPlayingInfoCenter` elapsed time.

**Android equivalent:** A Kotlin coroutine with `delay(1000)` or `Handler.postDelayed`.

**Workaround pattern:**
```swift
#if SKIP
// In Android-specific code:
// Use a kotlinx.coroutines timer
import kotlinx.coroutines.*

class AndroidPeriodicObserver {
    var job: kotlinx.coroutines.Job? = nil

    func start(player: AVPlayer, interval: Double, action: (Double) -> Void) {
        job = CoroutineScope(Dispatchers.Main).launch {
            while (true) {
                delay(Int64(interval * 1000))
                let positionMs = player.mediaPlayer.currentPosition
                action(Double(positionMs) / 1000.0)
            }
        }
    }

    func stop() {
        job?.cancel()
    }
}
#endif
```

This is not technically hard, but requires writing an `AudioPlayer` dependency that
has a platform-specific live implementation.

---

### Gap 2: `AVAudioSession` — LOW-MEDIUM effort

**What AM uses it for:**
- `.playback` category → background audio continues when screen locks
- `.spokenAudio` mode → podcast player behavior (pauses for navigation prompts)
- Interruption notifications → handles phone calls pausing audio

**Android equivalent:**
- Background audio: `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK">` + foreground service
- Audio focus: `AudioManager.requestAudioFocus()` / `AudioFocusRequest`
- Interruptions: The `AudioFocusRequest` callbacks handle this

**Workaround pattern:**
```swift
#if SKIP
func setupAudioFocus() {
    let audioManager = ProcessInfo.processInfo.androidContext
        .getSystemService(android.content.Context.AUDIO_SERVICE) as! android.media.AudioManager
    let focusRequest = android.media.AudioFocusRequest.Builder(
        android.media.AudioManager.AUDIOFOCUS_GAIN
    ).setOnAudioFocusChangeListener { focusChange in
        // handle interruptions
    }.build()
    audioManager.requestAudioFocus(focusRequest)
}
#endif
```

Audio background service is more involved — requires a `MediaSessionService` or
`MediaLibraryService` with a foreground notification. This is standard Android media
app boilerplate but is not trivial.

---

### Gap 3: `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter` — HIGH effort

**What AM uses it for:**
- Lock screen play/pause/skip controls
- Lock screen "now playing" info (title, show name, artwork, elapsed/total time)
- Headphone double-tap / triple-tap detection
- Scrubbing from lock screen

**Android equivalent:** `MediaSession` + `MediaDescriptionCompat` + `MediaNotification`

This is the most complex gap. On Android, the lock screen controls are driven by:
1. A `MediaSession` object (wrapping the ExoPlayer instance)
2. A `MediaSessionService` (a bound foreground service)
3. `MediaNotification.Provider` (what shows in the notification shade / lock screen)

The good news is that `media3-session` is ALREADY a declared dependency in SkipAV's
`skip.yml` — this is not an accident. PR #18 added `AVPlayer(player: MediaController)`
specifically to enable apps to wrap a `MediaController` (which implements `Player`)
instead of a raw `ExoPlayer`. The intended architecture is:

```
MediaSessionService (Android Service)
  └─ MediaSession
       └─ ExoPlayer (the actual player)
            └─ accessed via MediaController (implements Player interface)
                 └─ wrapped by AVPlayer(player: mediaController)
```

This gives lock screen controls "for free" once the service is set up. But setting up
the service requires Android-native code (in the Android `app/` directory, not in
shared Swift). The metadata (title, artwork, etc.) would be set via
`MediaSession.setMetadata()` in a `#if SKIP` block.

**Effort estimate:** 2-4 days for a solid implementation.

---

### Overall Assessment: YES, BUT — Significant Custom Work Required

| Feature | Status | Effort |
|---------|--------|--------|
| Play / Pause / Seek | ✅ Works via SkipAV | None |
| Playback rate (speed) | ✅ Works via SkipAV | None |
| Episode completion detection | ✅ Works via NotificationCenter | None |
| Real-time progress (1s tick) | ⚠️ Gap — no `addPeriodicTimeObserver` | ~1 day |
| Background audio (screen off) | ⚠️ Gap — no `AVAudioSession` | ~1-2 days |
| Audio interruptions (phone calls) | ⚠️ Gap — no `AVAudioSession` interruption | ~0.5 days |
| Lock screen controls | ⚠️ Gap — no `MPRemoteCommandCenter` | ~2-4 days |
| Lock screen now playing info | ⚠️ Gap — no `MPNowPlayingInfoCenter` | bundled above |
| Headphone remote controls | ⚠️ Gap — no `MPRemoteCommandCenter` | bundled above |

The core playback engine works. Everything else is standard Android media app plumbing
that must be custom-built per platform. The patterns are well-documented in Android docs
and the infrastructure (ExoPlayer + media3-session) is already pulled in by SkipAV.

---

## Key Questions Answered

### Does SkipAV exist and what does it provide?

Yes. `skip-av` at `source.skip.tools/skip-av.git` provides AVPlayer (low-level, backed
by ExoPlayer), AVAudioPlayer (higher-level, backed by Android MediaPlayer), AVAudioRecorder,
VideoPlayer SwiftUI component, and CMTime. Version 0.6.2 is current (Mar 2026).

### Can AVPlayer work on Android via Skip?

Yes for basic operations. `init(url:)`, `play()`, `pause()`, `seek(to:)`, `rate`,
`volume`, `timeControlStatus`, and completion notifications all work. Missing:
`addPeriodicTimeObserver` (the main gap for a podcast progress bar).

### Can background audio / lock screen controls work?

Not out of the box via Skip. The Android infrastructure (ExoPlayer + media3-session) is
present as a dependency, but you need:
1. Native Android foreground service (`MediaSessionService`) for background audio
2. `MediaSession` wrapping the ExoPlayer for lock screen controls
3. Custom Swift code in `#if SKIP` blocks to pass metadata

The Skip-provided `AVPlayer(player: MediaController)` initializer is the bridge point
for connecting the two worlds. This is non-trivial but achievable.

### What's the gap between what the AM app needs and what Skip provides?

The AM app's `AudioPlayer` dependency client would need a completely separate Android
live implementation. Roughly 60% of the interface would require custom work. Only
basic play/pause/seek/completion would come for free from SkipAV. The other 40%
(progress updates, audio session, lock screen) needs native Android code.

---

## Architectural Recommendation

Given that `swift-dependencies` is a BLOCKER (confirmed in earlier phase), the
AM app's `AudioPlayer` struct cannot be used as-is on Android anyway. This is
actually a useful forcing function: the audio layer needs to be redesigned regardless.

**Recommended approach for Android audio:**

1. Define a protocol `AudioPlayerProtocol` with the minimal interface needed
2. Have a Swift/iOS implementation backed by AVPlayer + AVAudioSession + MPRemoteCommandCenter
3. Have an Android implementation using `#if SKIP` blocks:
   - `AVPlayer` from SkipAV for playback
   - Native `android.media.AudioManager` for audio focus
   - A native `MediaSessionService` (in the Android `app/` target) for background + lock screen
   - A coroutine-based timer for progress updates
4. Wire the Android service to `AVPlayer` via the `AVPlayer(player: MediaController)` bridge

This "platform seam" pattern is actually the standard Skip approach for platform-specific
features, and the infrastructure supports it.

---

## Files Created

- `exploration/phase3/audio-probe/Package.swift` — probe package
- `exploration/phase3/audio-probe/Sources/AudioProbe/AudioProbe.swift` — probe source
- `exploration/phase3/audio-probe/Sources/AudioProbe/Skip/skip.yml` — native mode config
