import Foundation
import SwiftUI

#if os(iOS)
  public struct NowPlayingBarItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let artworkURL: URL?

    public init(
      id: String,
      title: String,
      artist: String,
      artworkURL: URL?,
    ) {
      self.id = id
      self.title = title
      self.artist = artist
      self.artworkURL = artworkURL
    }
  }

  public enum NowPlayingBarDisplayMode: Sendable {
    case automatic
    case expanded
    case inline
  }

  public struct NowPlayingBar: View {
    private let item: NowPlayingBarItem
    private let nextItem: NowPlayingBarItem?
    private let isPlaying: Bool
    private let isLoading: Bool
    private let isEnabled: Bool
    private let foregroundColor: Color
    private let displayMode: NowPlayingBarDisplayMode
    private let showsBackground: Bool
    private let onTap: @MainActor @Sendable () -> Void
    private let onPlayTap: @MainActor @Sendable () -> Void
    private let onNextTap: @MainActor @Sendable () -> Void

    public init(
      item: NowPlayingBarItem,
      nextItem: NowPlayingBarItem? = nil,
      isPlaying: Bool,
      isLoading: Bool,
      isEnabled: Bool,
      foregroundColor: Color,
      displayMode: NowPlayingBarDisplayMode,
      showsBackground: Bool,
      onTap: @MainActor @escaping @Sendable () -> Void,
      onPlayTap: @MainActor @escaping @Sendable () -> Void,
      onNextTap: @MainActor @escaping @Sendable () -> Void,
    ) {
      self.item = item
      self.nextItem = nextItem
      self.isPlaying = isPlaying
      self.isLoading = isLoading
      self.isEnabled = isEnabled
      self.foregroundColor = foregroundColor
      self.displayMode = displayMode
      self.showsBackground = showsBackground
      self.onTap = onTap
      self.onPlayTap = onPlayTap
      self.onNextTap = onNextTap
    }

    public var body: some View {
      if #available(iOS 26.0, *) {
        self.barContent
          .environment(\.backgroundMaterial, Material?.none)
      } else {
        self.barContent
      }
    }

    @ViewBuilder
    private var barContent: some View {
      let controls = NowPlayingBarContent(
        layout: self.layout,
        item: self.item,
        nextItem: self.nextItem,
        isPlaying: self.isPlaying,
        isLoading: self.isLoading,
        isEnabled: self.isEnabled,
        foregroundColor: self.foregroundColor,
        onTap: self.onTap,
        onPlayTap: self.onPlayTap,
        onNextTap: self.onNextTap,
      )
      let content = self.accessoryContent(controls)
      if self.showsBackground {
        if #available(iOS 26.0, *) {
          content
            .glassEffect(
              .regular.interactive(),
              in: RoundedRectangle(cornerRadius: self.panelCornerRadius, style: .continuous),
            )
        } else {
          content
            .clipShape(
              RoundedRectangle(cornerRadius: self.panelCornerRadius, style: .continuous),
            )
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

    private func accessoryContent(_ controls: some View) -> some View {
      ZStack(alignment: .bottom) {
        NowPlayingBarAtmosphere(isActive: self.isPlaying)
          .frame(maxWidth: .infinity)
          .frame(height: 32)
          .opacity(0.6)

        if self.showsBackground {
          controls
        } else {
          controls.padding(.vertical, 7)
        }
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
  }

  #if DEBUG
    #Preview("Playing accessory") {
      NowPlayingBar(
        item: NowPlayingBarItem(
          id: "current",
          title: PreviewMusicData.nowPlayingTitle,
          artist: PreviewMusicData.nowPlayingArtist,
          artworkURL: PreviewMusicData.nowPlayingArtworkURL,
        ),
        nextItem: NowPlayingBarItem(
          id: "next",
          title: "Stories",
          artist: "Alasdair Fraser & Natalie Haas",
          artworkURL: PreviewMusicData.storiesArtworkURL,
        ),
        isPlaying: true,
        isLoading: false,
        isEnabled: true,
        foregroundColor: .black,
        displayMode: .expanded,
        showsBackground: false,
        onTap: {},
        onPlayTap: {},
        onNextTap: {},
      )
      .background(Color(.secondarySystemBackground))
      .padding(24)
      .background(Color(.systemGroupedBackground))
    }
  #endif
#endif
