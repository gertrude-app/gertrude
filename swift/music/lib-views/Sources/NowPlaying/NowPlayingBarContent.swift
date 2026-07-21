import Foundation
import SwiftUI

#if os(iOS)
  enum NowPlayingBarLayout {
    case expanded
    case inline
  }

  struct NowPlayingBarContent: View {
    let layout: NowPlayingBarLayout
    let title: String
    let artist: String
    let artworkURL: URL?
    let isPlaying: Bool
    var isLoading = false
    let isEnabled: Bool
    let foregroundColor: Color
    let onTap: @MainActor @Sendable () -> Void
    let onPlayTap: @MainActor @Sendable () -> Void
    let onNextTap: @MainActor @Sendable () -> Void

    var body: some View {
      switch self.layout {
      case .expanded:
        self.expanded
      case .inline:
        self.inline
      }
    }

    private var expanded: some View {
      HStack(spacing: 12) {
        Button(action: self.onTap) {
          HStack(spacing: 10) {
            NowPlayingArtwork(
              url: self.artworkURL,
              size: 32,
              cornerRadius: 4,
            )
            NowPlayingBarText(
              title: self.title,
              artist: self.artist,
              foregroundColor: self.foregroundColor,
            )
          }
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          .clipped()
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minWidth: 0, maxWidth: .infinity)

        HStack(spacing: 2) {
          NowPlayingIconButton(
            systemName: self.isPlaying ? "pause.fill" : "play.fill",
            size: 18,
            foregroundColor: self.foregroundColor,
            isLoading: self.isLoading,
            isEnabled: self.isEnabled && !self.isLoading,
            accessibilityLabel: self.isLoading ? "Loading" : self.isPlaying ? "Pause" : "Play",
            action: self.onPlayTap,
          )
          NowPlayingIconButton(
            systemName: "forward.fill",
            size: 17,
            foregroundColor: self.foregroundColor,
            isEnabled: self.isEnabled,
            accessibilityLabel: "Next",
            action: self.onNextTap,
          )
        }
      }
      .padding(.leading, 15)
      .padding(.trailing, 22)
      .frame(height: 46)
    }

    private var inline: some View {
      HStack(spacing: 11) {
        Button(action: self.onTap) {
          HStack(spacing: 9) {
            NowPlayingArtwork(
              url: self.artworkURL,
              size: 30,
              cornerRadius: 7,
            )
            NowPlayingBarText(
              title: self.title,
              artist: self.artist,
              foregroundColor: self.foregroundColor,
            )
          }
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          .clipped()
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minWidth: 0, maxWidth: .infinity)

        NowPlayingIconButton(
          systemName: self.isPlaying ? "pause.fill" : "play.fill",
          size: 17,
          foregroundColor: self.foregroundColor,
          isLoading: self.isLoading,
          isEnabled: self.isEnabled && !self.isLoading,
          accessibilityLabel: self.isLoading ? "Loading" : self.isPlaying ? "Pause" : "Play",
          action: self.onPlayTap,
        )
      }
      .padding(.horizontal, 14)
      .frame(height: 44)
    }
  }

  private struct NowPlayingBarText: View {
    let title: String
    let artist: String
    let foregroundColor: Color

    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        Text(self.title)
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(self.foregroundColor)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)

        Text(self.artist)
          .font(.system(size: 12, weight: .regular, design: .rounded))
          .foregroundStyle(self.foregroundColor.opacity(0.86))
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .clipped()
      .mask(alignment: .trailing) {
        HStack(spacing: 0) {
          Rectangle()
          LinearGradient(
            stops: [
              .init(color: .black, location: 0),
              .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing,
          )
          .frame(width: 24)
        }
      }
    }
  }

  private struct NowPlayingArtwork: View {
    let url: URL?
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
      CachedArtworkImageView(url: self.url) { image in
        image
          .resizable()
          .scaledToFill()
          .frame(width: self.size, height: self.size)
          .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous))
      } placeholder: {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
          .fill(.secondary.opacity(0.18))
          .frame(width: self.size, height: self.size)
      }
    }
  }

  private struct NowPlayingIconButton: View {
    let systemName: String
    let size: CGFloat
    let foregroundColor: Color
    var isLoading = false
    let isEnabled: Bool
    let accessibilityLabel: String
    let action: @MainActor @Sendable () -> Void

    var body: some View {
      Button(action: self.action) {
        Group {
          if self.isLoading {
            ProgressView()
              .controlSize(.small)
              .tint(self.foregroundColor)
          } else {
            Image(systemName: self.systemName)
              .font(.system(size: self.size, weight: .black))
          }
        }
        .foregroundStyle(self.foregroundColor)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contentShape(Rectangle())
      .disabled(!self.isEnabled)
      .opacity(self.isEnabled ? 1 : 0.35)
      .accessibilityLabel(self.accessibilityLabel)
    }
  }

  #if DEBUG
    #Preview("Expanded") {
      NowPlayingBarContent(
        layout: .expanded,
        title: PreviewMusicData.nowPlayingTitle,
        artist: PreviewMusicData.nowPlayingArtist,
        artworkURL: PreviewMusicData.nowPlayingArtworkURL,
        isPlaying: true,
        isEnabled: true,
        foregroundColor: .black,
        onTap: {},
        onPlayTap: {},
        onNextTap: {},
      )
      .padding(24)
      .background(Color(.systemGroupedBackground))
    }

    #Preview("Inline") {
      NowPlayingBarContent(
        layout: .inline,
        title: PreviewMusicData.nowPlayingTitle,
        artist: PreviewMusicData.nowPlayingArtist,
        artworkURL: PreviewMusicData.nowPlayingArtworkURL,
        isPlaying: false,
        isEnabled: true,
        foregroundColor: .black,
        onTap: {},
        onPlayTap: {},
        onNextTap: {},
      )
      .padding(24)
      .background(Color(.systemGroupedBackground))
    }
  #endif
#endif
