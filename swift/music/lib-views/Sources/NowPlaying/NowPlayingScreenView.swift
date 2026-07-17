import Foundation
import SwiftUI

public struct NowPlayingScreenView: View {
  private let title: String
  private let artist: String
  private let artworkURL: URL?
  private let artworkTransitionID: String?
  private let isPlaying: Bool
  private let isLoading: Bool
  private let progress: Double
  private let duration: TimeInterval
  private let onPlayPauseTap: @MainActor @Sendable () -> Void
  private let onPreviousTap: @MainActor @Sendable () -> Void
  private let onNextTap: @MainActor @Sendable () -> Void
  private let onScrub: @MainActor @Sendable (TimeInterval) -> Void
  private let onAlbumInfoTap: (@MainActor @Sendable () -> Void)?

  public init(
    title: String,
    artist: String,
    artworkURL: URL?,
    artworkTransitionID: String?,
    isPlaying: Bool,
    isLoading: Bool,
    progress: Double,
    duration: TimeInterval,
    onPlayPauseTap: @MainActor @escaping @Sendable () -> Void,
    onPreviousTap: @MainActor @escaping @Sendable () -> Void,
    onNextTap: @MainActor @escaping @Sendable () -> Void,
    onScrub: @MainActor @escaping @Sendable (TimeInterval) -> Void,
    onAlbumInfoTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.title = title
    self.artist = artist
    self.artworkURL = artworkURL
    self.artworkTransitionID = artworkTransitionID
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.progress = progress
    self.duration = duration
    self.onPlayPauseTap = onPlayPauseTap
    self.onPreviousTap = onPreviousTap
    self.onNextTap = onNextTap
    self.onScrub = onScrub
    self.onAlbumInfoTap = onAlbumInfoTap
  }

  public var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black
          .ignoresSafeArea()

        CachedArtworkImageView(
          url: self.artworkURL,
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

          self.albumInfoView
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
  private var albumInfoView: some View {
    if let onAlbumInfoTap {
      Button(action: onAlbumInfoTap) {
        self.albumInfoText
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Open album")
    } else {
      self.albumInfoText
    }
  }

  private var albumInfoText: some View {
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
  }

  @ViewBuilder
  private func artworkView(size: CGFloat) -> some View {
    let artwork = AlbumArtworkView(
      artworkUrl: self.artworkURL,
      size: size,
      cornerRadius: 16,
    )
    #if os(iOS)
      if let artworkTransitionID {
        NowPlayingZoomRegisteredView(
          id: artworkTransitionID,
          role: .destination,
          cornerRadius: 16,
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

#if DEBUG
  #Preview("Now playing") {
    NowPlayingScreenView(
      title: PreviewMusicData.nowPlayingTitle,
      artist: PreviewMusicData.nowPlayingArtist,
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
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
