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
                .fill(Color(.secondarySystemBackground))
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
#endif
