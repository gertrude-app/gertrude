import Foundation
import SwiftUI

#if os(iOS)
  public enum NowPlayingBarDisplayMode: Sendable {
    case automatic
    case expanded
    case inline
  }

  public struct NowPlayingBar: View {
    private let title: String
    private let artist: String
    private let artworkURL: URL?
    private let isPlaying: Bool
    private let isLoading: Bool
    private let isEnabled: Bool
    private let foregroundColor: Color
    private let panelTransitionID: String?
    private let artworkTransitionID: String?
    private let displayMode: NowPlayingBarDisplayMode
    private let showsBackground: Bool
    private let onTap: @MainActor @Sendable () -> Void
    private let onPlayTap: @MainActor @Sendable () -> Void
    private let onNextTap: @MainActor @Sendable () -> Void

    public init(
      title: String,
      artist: String,
      artworkURL: URL?,
      isPlaying: Bool,
      isLoading: Bool,
      isEnabled: Bool,
      foregroundColor: Color,
      panelTransitionID: String?,
      artworkTransitionID: String?,
      displayMode: NowPlayingBarDisplayMode,
      showsBackground: Bool,
      onTap: @MainActor @escaping @Sendable () -> Void,
      onPlayTap: @MainActor @escaping @Sendable () -> Void,
      onNextTap: @MainActor @escaping @Sendable () -> Void,
    ) {
      self.title = title
      self.artist = artist
      self.artworkURL = artworkURL
      self.isPlaying = isPlaying
      self.isLoading = isLoading
      self.isEnabled = isEnabled
      self.foregroundColor = foregroundColor
      self.panelTransitionID = panelTransitionID
      self.artworkTransitionID = artworkTransitionID
      self.displayMode = displayMode
      self.showsBackground = showsBackground
      self.onTap = onTap
      self.onPlayTap = onPlayTap
      self.onNextTap = onNextTap
    }

    public var body: some View {
      if #available(iOS 26.0, *) {
        self.withPanelTransitionSource(
          self.barContent
            .environment(\.backgroundMaterial, Material?.none),
        )
      } else {
        self.withPanelTransitionSource(self.barContent)
      }
    }

    @ViewBuilder
    private var barContent: some View {
      let content = NowPlayingBarContent(
        layout: self.layout,
        title: self.title,
        artist: self.artist,
        artworkURL: self.artworkURL,
        artworkTransitionID: self.artworkTransitionID,
        isPlaying: self.isPlaying,
        isLoading: self.isLoading,
        isEnabled: self.isEnabled,
        foregroundColor: self.foregroundColor,
        onTap: self.onTap,
        onPlayTap: self.onPlayTap,
        onNextTap: self.onNextTap,
      )
      if self.showsBackground {
        if #available(iOS 26.0, *) {
          content
            .glassEffect(
              .regular.interactive(),
              in: RoundedRectangle(cornerRadius: self.panelCornerRadius, style: .continuous),
            )
        } else {
          content
            .background {
              RoundedRectangle(cornerRadius: self.panelCornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 7)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
            }
            .overlay {
              RoundedRectangle(cornerRadius: self.panelCornerRadius, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
            }
        }
      } else {
        content
      }
    }

    private var layout: NowPlayingBarLayout {
      switch self.displayMode {
      case .automatic, .expanded:
        .expanded
      case .inline:
        .inline
      }
    }

    private var panelCornerRadius: CGFloat {
      self.layout == .inline ? 20 : 24
    }

    private var panelHeight: CGFloat {
      self.layout == .inline ? 40 : 46
    }

    @ViewBuilder
    private func withPanelTransitionSource(_ content: some View) -> some View {
      if let panelTransitionID {
        NowPlayingZoomRegisteredView(
          id: panelTransitionID,
          role: .source,
          cornerRadius: self.panelCornerRadius,
          allowsInteraction: true,
        ) {
          content
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.panelHeight)
      } else {
        content
      }
    }
  }

  private enum NowPlayingBarLayout {
    case expanded
    case inline
  }

  private struct NowPlayingBarContent: View {
    let layout: NowPlayingBarLayout
    let title: String
    let artist: String
    let artworkURL: URL?
    let artworkTransitionID: String?
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
              cornerRadius: 7,
              transitionID: self.artworkTransitionID,
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

        HStack(spacing: 18) {
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
            hitSlop: .init(width: 12, height: 8),
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
              transitionID: self.artworkTransitionID,
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
      .padding(.leading, 14)
      .padding(.trailing, 22)
      .frame(height: 40)
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
    let transitionID: String?

    var body: some View {
      if let transitionID {
        NowPlayingZoomRegisteredView(
          id: transitionID,
          role: .source,
          cornerRadius: self.cornerRadius,
        ) {
          self.artwork
        }
        .frame(width: self.size, height: self.size)
      } else {
        self.artwork
      }
    }

    private var artwork: some View {
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
    var hitSlop: CGSize = .zero
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
        .frame(width: max(28, self.size + 8), height: 30)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding(.horizontal, self.hitSlop.width)
      .padding(.vertical, self.hitSlop.height)
      .contentShape(Rectangle())
      .padding(.horizontal, -self.hitSlop.width)
      .padding(.vertical, -self.hitSlop.height)
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
        artworkTransitionID: nil,
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
        artworkTransitionID: nil,
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
