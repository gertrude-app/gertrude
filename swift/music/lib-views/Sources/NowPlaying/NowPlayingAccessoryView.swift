import Foundation
import SwiftUI

#if os(iOS)
  @available(iOS 26.0, *)
  public struct NowPlayingAccessoryView: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    private let title: String
    private let artist: String
    private let artworkURL: URL?
    private let foregroundColor: Color
    private let onTap: @MainActor @Sendable () -> Void
    private let onPlayTap: @MainActor @Sendable () -> Void
    private let onSkipTap: @MainActor @Sendable () -> Void

    public init(
      title: String = "Josefin’s Waltz",
      artist: String = "Alasdair Fraser & Natalie Haas",
      artworkURL: URL? = URL(
        string:
          "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
      ),
      foregroundColor: Color = .black,
      onTap: @MainActor @escaping @Sendable () -> Void = {},
      onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
      onSkipTap: @MainActor @escaping @Sendable () -> Void = {},
    ) {
      self.title = title
      self.artist = artist
      self.artworkURL = artworkURL
      self.foregroundColor = foregroundColor
      self.onTap = onTap
      self.onPlayTap = onPlayTap
      self.onSkipTap = onSkipTap
    }

    public var body: some View {
      NowPlayingAccessoryContent(
        layout: self.placement == .inline ? .inline : .expanded,
        title: self.title,
        artist: self.artist,
        artworkURL: self.artworkURL,
        foregroundColor: self.foregroundColor,
        onTap: self.onTap,
        onPlayTap: self.onPlayTap,
        onSkipTap: self.onSkipTap,
      )
      .environment(\.backgroundMaterial, Optional<Material>.none)
      .animation(.snappy(duration: 0.24), value: self.placement)
    }
  }

  private enum NowPlayingAccessoryLayout {
    case expanded
    case inline
  }

  private struct NowPlayingAccessoryContent: View {
    let layout: NowPlayingAccessoryLayout
    let title: String
    let artist: String
    let artworkURL: URL?
    let foregroundColor: Color
    let onTap: @MainActor @Sendable () -> Void
    let onPlayTap: @MainActor @Sendable () -> Void
    let onSkipTap: @MainActor @Sendable () -> Void

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
            NowPlayingArtwork(url: self.artworkURL, size: 32, cornerRadius: 7)
            NowPlayingAccessoryText(
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
            systemName: "play.fill",
            size: 18,
            foregroundColor: self.foregroundColor,
            action: self.onPlayTap,
          )
          NowPlayingIconButton(
            systemName: "forward.fill",
            size: 17,
            foregroundColor: self.foregroundColor,
            action: self.onSkipTap,
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
            NowPlayingArtwork(url: self.artworkURL, size: 30, cornerRadius: 7)
            NowPlayingAccessoryText(
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
          systemName: "play.fill",
          size: 17,
          foregroundColor: self.foregroundColor,
          action: self.onPlayTap,
        )
      }
      .padding(.leading, 14)
      .padding(.trailing, 22)
      .frame(height: 40)
    }
  }

  private struct NowPlayingAccessoryText: View {
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
          .clipShape(.rect(cornerRadius: self.cornerRadius, style: .continuous))
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
    let action: @MainActor @Sendable () -> Void

    var body: some View {
      Button(action: self.action) {
        Image(systemName: self.systemName)
          .font(.system(size: self.size, weight: .black))
          .foregroundStyle(self.foregroundColor)
          .frame(width: max(28, self.size + 8), height: 30)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(self.systemName == "play.fill" ? "Play" : "Next")
    }
  }

  #Preview("Expanded") {
    NowPlayingAccessoryContent(
      layout: .expanded,
      title: "Josefin’s Waltz",
      artist: "Alasdair Fraser & Natalie Haas",
      artworkURL: URL(
        string:
          "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
      ),
      foregroundColor: .black,
      onTap: {},
      onPlayTap: {},
      onSkipTap: {},
    )
    .padding(24)
    .background(Color(.systemGroupedBackground))
  }

  #Preview("Inline") {
    NowPlayingAccessoryContent(
      layout: .inline,
      title: "Josefin’s Waltz",
      artist: "Alasdair Fraser & Natalie Haas",
      artworkURL: URL(
        string:
          "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
      ),
      foregroundColor: .black,
      onTap: {},
      onPlayTap: {},
      onSkipTap: {},
    )
    .padding(24)
    .background(Color(.systemGroupedBackground))
  }
#endif
