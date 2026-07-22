import Foundation
import SwiftUI

public struct NowPlayingScreenView: View {
  private let title: String
  private let artist: String
  private let artworkURL: URL?
  private let showsBackground: Bool
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
    showsBackground: Bool = true,
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
    self.showsBackground = showsBackground
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
        if self.showsBackground {
          NowPlayingBackgroundView(artworkURL: self.artworkURL)
        }

        switch self.layout(for: proxy.size) {
        case .vertical:
          self.verticalContent(in: proxy.size)
        case .horizontal:
          self.horizontalContent(in: proxy.size)
        case .compact:
          self.compactContent(in: proxy.size)
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
    }
  }

  private func verticalContent(in size: CGSize) -> some View {
    VStack(spacing: 0) {
      self.dragIndicator

      Spacer(minLength: 18)

      self.artworkView(size: self.verticalArtworkSize(for: size))

      self.albumInfoView
        .frame(maxWidth: 520)
        .padding(.horizontal, 12)
        .padding(.top, 20)

      self.transportControls
        .padding(.top, 36)
        .padding(.bottom, 36)

      self.progressBar
        .frame(maxWidth: 560)
        .padding(.horizontal, 2)

      Spacer(minLength: 22)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 32)
    .padding(.vertical, 8)
  }

  private func horizontalContent(in size: CGSize) -> some View {
    let horizontalPadding = min(48, max(24, size.width * 0.05))
    let contentSpacing = min(36, max(24, size.width * 0.04))
    let artworkSize = self.horizontalArtworkSize(
      for: size,
      horizontalPadding: horizontalPadding,
      contentSpacing: contentSpacing,
    )

    return VStack(spacing: 0) {
      self.dragIndicator

      Spacer(minLength: 12)

      HStack(spacing: contentSpacing) {
        self.artworkView(size: artworkSize)

        VStack(spacing: 24) {
          self.albumInfoView
            .frame(maxWidth: 460)

          self.transportControls

          self.progressBar
            .frame(maxWidth: 500)
        }
        .frame(maxWidth: .infinity)
      }

      Spacer(minLength: 12)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, horizontalPadding)
    .padding(.vertical, 8)
  }

  private func compactContent(in size: CGSize) -> some View {
    ScrollView {
      VStack(spacing: 0) {
        self.dragIndicator

        self.artworkView(size: self.compactArtworkSize(for: size))
          .padding(.top, 16)

        self.albumInfoView
          .padding(.horizontal, 8)
          .padding(.top, 16)

        self.transportControls
          .padding(.top, 22)

        self.progressBar
          .padding(.top, 22)
          .padding(.bottom, 24)
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: size.height, alignment: .top)
      .padding(.horizontal, 24)
      .padding(.vertical, 8)
    }
    .scrollIndicators(.hidden)
  }

  private var dragIndicator: some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(.white.opacity(0.3))
      .frame(width: 60, height: 4)
  }

  private var transportControls: some View {
    NowPlayingTransportControls(
      isPlaying: self.isPlaying,
      isLoading: self.isLoading,
      onPlayPauseTap: self.onPlayPauseTap,
      onPreviousTap: self.onPreviousTap,
      onNextTap: self.onNextTap,
    )
  }

  private var progressBar: some View {
    NowPlayingProgressBar(
      progress: self.progress,
      duration: self.duration,
      onScrub: self.onScrub,
    )
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

  private func artworkView(size: CGFloat) -> some View {
    AlbumArtworkView(
      artworkUrl: self.artworkURL,
      size: size,
      cornerRadius: 16,
    )
  }

  private func layout(for size: CGSize) -> NowPlayingScreenLayout {
    if size.width >= 560,
       size.height < 620 || size.width > size.height * 1.18 {
      return .horizontal
    }
    if size.height >= 560 {
      return .vertical
    }
    return .compact
  }

  private func verticalArtworkSize(for size: CGSize) -> CGFloat {
    min(
      330,
      max(1, size.width - 64),
      max(140, size.height * 0.43),
    )
  }

  private func horizontalArtworkSize(
    for size: CGSize,
    horizontalPadding: CGFloat,
    contentSpacing: CGFloat,
  ) -> CGFloat {
    let availableWidth = max(1, size.width - horizontalPadding * 2 - contentSpacing)
    return min(
      330,
      availableWidth * 0.44,
      max(1, size.height - 72),
    )
  }

  private func compactArtworkSize(for size: CGSize) -> CGFloat {
    min(
      220,
      max(1, size.width - 48),
      max(120, size.height * 0.34),
    )
  }
}

private enum NowPlayingScreenLayout {
  case vertical
  case horizontal
  case compact
}

#if DEBUG
  #Preview("Now playing") {
    NowPlayingScreenView(
      title: PreviewMusicData.nowPlayingTitle,
      artist: PreviewMusicData.nowPlayingArtist,
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
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

  #Preview("Now playing compact") {
    NowPlayingScreenView(
      title: "A Long Tune Title That Wraps Gracefully",
      artist: "An Artist With a Long Display Name",
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
      isPlaying: true,
      isLoading: false,
      progress: 0.38,
      duration: 214,
      onPlayPauseTap: {},
      onPreviousTap: {},
      onNextTap: {},
      onScrub: { _ in },
    )
    .frame(width: 320, height: 480)
  }

  #Preview("Now playing short and wide") {
    NowPlayingScreenView(
      title: PreviewMusicData.nowPlayingTitle,
      artist: PreviewMusicData.nowPlayingArtist,
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
      isPlaying: true,
      isLoading: false,
      progress: 0.38,
      duration: 214,
      onPlayPauseTap: {},
      onPreviousTap: {},
      onNextTap: {},
      onScrub: { _ in },
    )
    .frame(width: 700, height: 400)
  }

  #Preview("Now playing minimum window") {
    NowPlayingScreenView(
      title: "A Long Tune Title That Wraps Gracefully",
      artist: "An Artist With a Long Display Name",
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
      isPlaying: true,
      isLoading: false,
      progress: 0.38,
      duration: 214,
      onPlayPauseTap: {},
      onPreviousTap: {},
      onNextTap: {},
      onScrub: { _ in },
    )
    .frame(width: 320, height: 320)
  }

  #Preview("Now playing tall and narrow") {
    NowPlayingScreenView(
      title: PreviewMusicData.nowPlayingTitle,
      artist: PreviewMusicData.nowPlayingArtist,
      artworkURL: PreviewMusicData.nowPlayingArtworkURL,
      isPlaying: true,
      isLoading: false,
      progress: 0.38,
      duration: 214,
      onPlayPauseTap: {},
      onPreviousTap: {},
      onNextTap: {},
      onScrub: { _ in },
    )
    .frame(width: 420, height: 900)
  }
#endif
