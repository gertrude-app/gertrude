import AVFoundation
import Foundation
#if canImport(MediaPlayer)
import MediaPlayer
#endif

// Probe 1: AVPlayer basics — supported by SkipAV (orange/low level)
// Covers: init(url:), play(), pause()
public func probeAVPlayerCreate(url: URL) -> AVPlayer {
    let player = AVPlayer(url: url)
    return player
}

public func probeAVPlayerPlay(player: AVPlayer) {
    player.play()
}

public func probeAVPlayerPause(player: AVPlayer) {
    player.pause()
}

// Probe 2: AVPlayer seek — supported in SkipAV
public func probeAVPlayerSeek(player: AVPlayer, seconds: Double) {
    player.seek(to: CMTime(seconds: seconds, preferredTimescale: 30))
}

// Probe 3: AVPlayer rate (playback speed) — supported in SkipAV
public func probePlaybackRate(player: AVPlayer) {
    player.rate = 1.5
}

// Probe 4: AVPlayer timeControlStatus — added in SkipAV 0.6.2
public func probeTimeControlStatus(player: AVPlayer) -> Bool {
    return player.timeControlStatus == .playing
}

// Probe 5: AVPlayerItem notifications — supported in SkipAV
// .didPlayToEndTimeNotification and .timeJumpedNotification work via NotificationCenter
public func probeAVPlayerItemNotifications(player: AVPlayer) {
    NotificationCenter.default.addObserver(
        forName: AVPlayerItem.didPlayToEndTimeNotification,
        object: player.currentItem,
        queue: .main
    ) { _ in
    }
}

// Probe 6: AVAudioPlayer — high support in SkipAV (green level)
// Covers: init(contentsOf:), play(), pause(), stop(), currentTime, rate, volume, duration
public func probeAVAudioPlayer(url: URL) throws -> AVAudioPlayer {
    let player = try AVAudioPlayer(contentsOf: url)
    _ = player.duration
    _ = player.currentTime
    player.volume = 0.8
    player.rate = 1.5
    player.play()
    return player
}

// Probe 7: AVAudioSession — iOS-only, NOT in SkipAV
// The AM app uses this for .playback category + interruption handling
// On Android, audio focus must be requested via AudioManager in native Kotlin/Java
#if os(iOS) && !SKIP
public func probeAVAudioSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback)
    try? session.setMode(.spokenAudio)
    try? session.setActive(true)

    NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: AVAudioSession.sharedInstance(),
        queue: .main
    ) { notification in
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            break
        case .ended:
            break
        @unknown default:
            break
        }
    }
}
#endif

// Probe 8: addPeriodicTimeObserver — NOT in SkipAV
// The AM app uses this for real-time progress updates (every 1 second)
// On Android would need to be implemented via Handler.postDelayed or coroutine timer
#if !SKIP
public func probePeriodicTimeObserver(player: AVPlayer) -> Any {
    let token = player.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 1.0, preferredTimescale: 1),
        queue: .main
    ) { time in
        let _ = time.seconds
    }
    return token
}
#endif

// Probe 9: MPRemoteCommandCenter — NOT in SkipAV
// The AM app uses this for lock screen controls (play/pause/skip/scrub/headphone clicks)
// On Android, equivalent is MediaSession + MediaButtonReceiver
#if canImport(MediaPlayer) && !SKIP
public func probeMPRemoteCommandCenter() {
    let commands = MPRemoteCommandCenter.shared()
    commands.playCommand.addTarget { _ in .success }
    commands.pauseCommand.addTarget { _ in .success }
    commands.skipForwardCommand.isEnabled = true
    commands.skipForwardCommand.preferredIntervals = [NSNumber(value: 30)]
    commands.skipForwardCommand.addTarget { _ in .success }
    commands.skipBackwardCommand.isEnabled = true
    commands.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
    commands.skipBackwardCommand.addTarget { _ in .success }
    commands.nextTrackCommand.isEnabled = true
    commands.nextTrackCommand.addTarget { _ in .success }
    commands.previousTrackCommand.isEnabled = true
    commands.previousTrackCommand.addTarget { _ in .success }
}

// Probe 10: MPNowPlayingInfoCenter — NOT in SkipAV
// Lock screen "now playing" info (title, artist, artwork, progress, duration)
// On Android, handled by MediaSession.setMetadata() + MediaNotification
public func probeMPNowPlayingInfoCenter(title: String, artist: String, duration: Double, elapsed: Double) {
    let nowPlayingInfo: [String: Any] = [
        MPMediaItemPropertyTitle: title,
        MPMediaItemPropertyArtist: artist,
        MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
        MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        MPMediaItemPropertyPlaybackDuration: duration,
    ]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}
#endif
