import Foundation
import SwiftUI

public struct NowPlayingScreenView: View {
  private let title: String
  private let artist: String
  private let artworkURL: URL?
  private let showsArtwork: Bool
  private let artworkTransitionID: String?
  private let isPlaying: Bool
  private let isLoading: Bool
  private let progress: Double
  private let duration: TimeInterval
  private let onPlayPauseTap: @MainActor @Sendable () -> Void
  private let onPreviousTap: @MainActor @Sendable () -> Void
  private let onNextTap: @MainActor @Sendable () -> Void
  private let onScrub: @MainActor @Sendable (TimeInterval) -> Void

  public init(
    title: String,
    artist: String,
    artworkURL: URL?,
    showsArtwork: Bool,
    artworkTransitionID: String?,
    isPlaying: Bool,
    isLoading: Bool,
    progress: Double,
    duration: TimeInterval,
    onPlayPauseTap: @MainActor @escaping @Sendable () -> Void,
    onPreviousTap: @MainActor @escaping @Sendable () -> Void,
    onNextTap: @MainActor @escaping @Sendable () -> Void,
    onScrub: @MainActor @escaping @Sendable (TimeInterval) -> Void,
  ) {
    self.title = title
    self.artist = artist
    self.artworkURL = artworkURL
    self.showsArtwork = showsArtwork
    self.artworkTransitionID = artworkTransitionID
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.progress = progress
    self.duration = duration
    self.onPlayPauseTap = onPlayPauseTap
    self.onPreviousTap = onPreviousTap
    self.onNextTap = onNextTap
    self.onScrub = onScrub
  }

  public var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black
          .ignoresSafeArea()

        CachedArtworkImageView(
          url: self.showsArtwork ? self.artworkURL : nil,
        ) { image in
          image
            .resizable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(1.2)
            .clipped()
            .ignoresSafeArea()
            .blur(radius: 80)
            .opacity(0.7)
        } placeholder: {
          Color.clear
            .frame(width: 100, height: 100)
        }

        VStack(spacing: 0) {
          RoundedRectangle(cornerRadius: 2)
            .fill(.white.opacity(0.3))
            .frame(width: 60, height: 4)

          Spacer(minLength: 18)

          self.artworkView(size: self.artworkSize(for: proxy.size))

          VStack(spacing: 4) {
            Text(self.title)
              .font(
                .system(
                  size: 24,
                  weight: .bold,
                  design: .rounded,
                ),
              )
              .foregroundStyle(.white)
              .multilineTextAlignment(.center)
              .lineLimit(2)

            Text(self.artist)
              .font(
                .system(
                  size: 17,
                  weight: .semibold,
                  design: .rounded,
                ),
              )
              .foregroundStyle(.white.opacity(0.7))
              .multilineTextAlignment(.center)
              .lineLimit(2)
          }
          .padding(.horizontal, 12)
          .padding(.top, 20)

          NowPlayingTransportControls(
            isPlaying: self.isPlaying,
            isLoading: self.isLoading,
            onPlayPauseTap: self.onPlayPauseTap,
            onPreviousTap: self.onPreviousTap,
            onNextTap: self.onNextTap,
          )
          .padding(.top, 36)
          .padding(.bottom, 36)

          NowPlayingProgressBar(
            progress: self.progress,
            duration: self.duration,
            onScrub: self.onScrub,
          )
          .padding(.horizontal, 2)

          Spacer(minLength: 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
      }
    }
  }

  @ViewBuilder
  private func artworkView(size: CGFloat) -> some View {
    let artwork = AlbumArtworkView(
      artworkUrl: self.artworkURL,
      showsArtwork: self.showsArtwork,
      size: size,
      cornerRadius: 34,
    )
    #if os(iOS)
      if let artworkTransitionID {
        NowPlayingZoomRegisteredView(
          id: artworkTransitionID,
          role: .destination,
          cornerRadius: 34,
        ) {
          artwork
        }
        .frame(width: size, height: size)
      } else {
        artwork
      }
    #else
      artwork
    #endif
  }

  private func artworkSize(for size: CGSize) -> CGFloat {
    min(330, max(210, min(size.width - 72, size.height * 0.43)))
  }
}

private struct NowPlayingTransportControls: View {
  let isPlaying: Bool
  let isLoading: Bool
  let onPlayPauseTap: @MainActor @Sendable () -> Void
  let onPreviousTap: @MainActor @Sendable () -> Void
  let onNextTap: @MainActor @Sendable () -> Void

  var body: some View {
    HStack(spacing: 34) {
      NowPlayingSecondaryControlButton(
        systemName: "backward.fill",
        accessibilityLabel: "Previous",
        action: self.onPreviousTap,
      )

      Button(action: self.onPlayPauseTap) {
        Group {
          if self.isLoading {
            ProgressView()
              .controlSize(.large)
              .tint(.white)
          } else {
            Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
              .font(.system(size: 42, weight: .black))
          }
        }
        .foregroundStyle(.white)
        .frame(width: 58, height: 58)
        .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(self.isLoading)
      .accessibilityLabel(self.isLoading ? "Loading" : self.isPlaying ? "Pause" : "Play")

      NowPlayingSecondaryControlButton(
        systemName: "forward.fill",
        accessibilityLabel: "Next",
        action: self.onNextTap,
      )
    }
  }
}

private struct NowPlayingSecondaryControlButton: View {
  let systemName: String
  let accessibilityLabel: String
  let action: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.action) {
      Image(systemName: self.systemName)
        .font(.system(size: 27, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 58, height: 58)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
  }
}

private struct NowPlayingProgressBar: View {
  let progress: Double
  let duration: TimeInterval
  let onScrub: @MainActor @Sendable (TimeInterval) -> Void

  @State private var scrubbedProgress: Double?
  @State private var isScrubbing = false

  var body: some View {
    VStack(spacing: 9) {
      GeometryReader { proxy in
        ZStack(alignment: .center) {
          ZStack(alignment: .leading) {
            Capsule()
              .fill(.white.opacity(0.18))

            Capsule()
              .fill(.white)
              .frame(width: proxy.size.width * self.displayedProgress)
          }
          .frame(height: 9)
          .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(self.dragGesture(width: proxy.size.width))
      }
      .frame(height: 28)

      HStack {
        Text(self.formattedTime(self.elapsedTime))

        Spacer(minLength: 12)

        Text("-\(self.formattedTime(self.remainingTime))")
      }
      .font(.system(size: 12, weight: .semibold, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(.white.opacity(0.7))
    }
    .onChange(of: self.progress) { _, _ in
      if !self.isScrubbing {
        self.scrubbedProgress = nil
      }
    }
  }

  private func dragGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        guard self.canScrub, width > 0 else { return }
        let progress = self.progress(for: value.location.x, width: width)
        self.isScrubbing = true
        self.scrubbedProgress = progress
        self.onScrub(self.time(for: progress))
      }
      .onEnded { value in
        guard self.canScrub, width > 0 else {
          self.isScrubbing = false
          self.scrubbedProgress = nil
          return
        }
        let progress = self.progress(for: value.location.x, width: width)
        self.scrubbedProgress = progress
        self.onScrub(self.time(for: progress))
        self.isScrubbing = false
      }
  }

  private var canScrub: Bool {
    self.duration.isFinite && self.duration > 0
  }

  private var displayedProgress: Double {
    self.scrubbedProgress ?? self.clampedProgress
  }

  private var clampedProgress: Double {
    min(1, max(0, self.progress))
  }

  private var elapsedTime: TimeInterval {
    max(0, self.duration) * self.displayedProgress
  }

  private var remainingTime: TimeInterval {
    max(0, max(0, self.duration) - self.elapsedTime)
  }

  private func progress(for locationX: CGFloat, width: CGFloat) -> Double {
    min(1, max(0, Double(locationX / width)))
  }

  private func time(for progress: Double) -> TimeInterval {
    max(0, self.duration) * min(1, max(0, progress))
  }

  private func formattedTime(_ time: TimeInterval) -> String {
    let rounded = max(0, Int(time.rounded()))
    return "\(rounded / 60):\(String(format: "%02d", rounded % 60))"
  }
}

#if DEBUG
  #Preview("Now playing") {
    NowPlayingScreenView(
      title: PreviewMusicData.nowPlayingTitle,
      artist: PreviewMusicData.nowPlayingArtist,
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
      showsArtwork: true,
      artworkTransitionID: nil,
      isPlaying: true,
      isLoading: false,
      progress: 0.38,
      duration: 214,
      onPlayPauseTap: {},
      onPreviousTap: {},
      onNextTap: {},
      onScrub: { _ in },
    )
  }

  #Preview("Now playing paused") {
    NowPlayingScreenView(
      title: PreviewMusicData.nowPlayingTitle,
      artist: PreviewMusicData.nowPlayingArtist,
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
      showsArtwork: true,
      artworkTransitionID: nil,
      isPlaying: false,
      isLoading: false,
      progress: 0.62,
      duration: 214,
      onPlayPauseTap: {},
      onPreviousTap: {},
      onNextTap: {},
      onScrub: { _ in },
    )
  }

  #Preview("Now playing no artwork") {
    NowPlayingScreenView(
      title: "A Long Tune Title That Wraps Gracefully",
      artist: "Unknown Artist",
      artworkURL: nil,
      showsArtwork: false,
      artworkTransitionID: nil,
      isPlaying: false,
      isLoading: false,
      progress: 0,
      duration: 214,
      onPlayPauseTap: {},
      onPreviousTap: {},
      onNextTap: {},
      onScrub: { _ in },
    )
  }
#endif
