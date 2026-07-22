import SwiftUI

public func playlistArtworkZoomTransitionID(for playlistID: String) -> String {
  "playlist-artwork-\(playlistID)"
}

public struct PlaylistArtworkView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let tiles: [PlaylistArtworkTile]
  private let columnCount: Int
  private let size: CGFloat
  private let cornerRadius: CGFloat

  public init(
    artworkUrls: [URL],
    size: CGFloat = 148,
    cornerRadius: CGFloat = 12,
  ) {
    let layout = PlaylistArtworkLayout(artworkUrls: artworkUrls)
    self.tiles = layout.tiles
    self.columnCount = layout.columnCount
    self.size = size
    self.cornerRadius = cornerRadius
  }

  public init(
    playlist: PlaylistData,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 12,
  ) {
    let layout = PlaylistArtworkLayout(artworkUrls: playlist.artworkUrls)
    self.tiles = layout.tiles
    self.columnCount = layout.columnCount
    self.size = size
    self.cornerRadius = cornerRadius
  }

  public var body: some View {
    ZStack {
      self.backdrop

      ZStack {
        self.blurredArtworkTint
        self.insetContent
      }
      .frame(width: self.size, height: self.size)
      .compositingGroup()
      .clipShape(
        .rect(cornerRadius: self.cornerRadius, style: .continuous),
      )
    }
    .frame(width: self.size, height: self.size)
    .compositingGroup()
    .clipShape(
      .rect(cornerRadius: self.cornerRadius, style: .continuous),
    )
    .shadow(color: self.shadowColor, radius: 9, y: 5)
    .accessibilityHidden(true)
  }

  @ViewBuilder private var backdrop: some View {
    if #available(iOS 26.0, macOS 26.0, *) {
      Color.clear
        .frame(width: self.size, height: self.size)
        .glassEffect(
          .regular,
          in: .rect(cornerRadius: self.cornerRadius),
        )
    } else {
      RoundedRectangle(
        cornerRadius: self.cornerRadius,
        style: .continuous,
      )
      .fill(.ultraThinMaterial)
      .overlay {
        RoundedRectangle(
          cornerRadius: self.cornerRadius,
          style: .continuous,
        )
        .strokeBorder(self.borderColor, lineWidth: 1)
      }
    }
  }

  @ViewBuilder private var blurredArtworkTint: some View {
    if !self.tiles.isEmpty {
      self.insetContent
        .frame(width: self.size, height: self.size)
        .blur(radius: self.size * 0.05)
        .opacity(0.8)
        .allowsHitTesting(false)
    }
  }

  @ViewBuilder private var insetContent: some View {
    if self.tiles.isEmpty {
      Image(systemName: "music.note")
        .font(.system(size: self.size * 0.28, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: self.contentSize, height: self.contentSize)
    } else {
      LazyVGrid(columns: self.columns, spacing: self.tileSpacing) {
        ForEach(self.tiles) { tile in
          PlaylistArtworkTileView(
            url: tile.url,
            size: self.tileSize,
            innerCornerRadius: self.innerTileCornerRadius,
            outerCornerRadius: self.outerTileCornerRadius,
            corners: tile.corners,
            index: tile.id,
          )
        }
      }
      .frame(width: self.contentSize, height: self.contentSize)
    }
  }

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(
        .fixed(self.tileSize),
        spacing: self.tileSpacing,
      ),
      count: self.columnCount,
    )
  }

  private var outerPadding: CGFloat {
    self.size * 0.027
  }

  private var tileSpacing: CGFloat {
    self.size * 0.027
  }

  private var contentSize: CGFloat {
    self.size - self.outerPadding * 2
  }

  private var tileSize: CGFloat {
    let totalSpacing = self.tileSpacing * CGFloat(self.columnCount - 1)
    return (self.contentSize - totalSpacing) / CGFloat(self.columnCount)
  }

  private var innerTileCornerRadius: CGFloat {
    3
  }

  private var outerTileCornerRadius: CGFloat {
    max(0, self.cornerRadius - self.outerPadding)
  }

  private var borderColor: Color {
    Color(
      self.colorScheme,
      light: .white.opacity(0.5),
      dark: .white.opacity(0.16),
    )
  }

  private var shadowColor: Color {
    Color(
      self.colorScheme,
      light: .black.opacity(0.18),
      dark: .black.opacity(0.32),
    )
  }
}

private struct PlaylistArtworkTileView: View {
  @Environment(\.colorScheme) private var colorScheme

  let url: URL?
  let size: CGFloat
  let innerCornerRadius: CGFloat
  let outerCornerRadius: CGFloat
  let corners: PlaylistArtworkTileCorners
  let index: Int

  var body: some View {
    self.tileContent
      .compositingGroup()
      .clipShape(
        UnevenRoundedRectangle(
          topLeadingRadius: self.corners.topLeading
            ? self.outerCornerRadius : self.innerCornerRadius,
          bottomLeadingRadius: self.corners.bottomLeading
            ? self.outerCornerRadius : self.innerCornerRadius,
          bottomTrailingRadius: self.corners.bottomTrailing
            ? self.outerCornerRadius : self.innerCornerRadius,
          topTrailingRadius: self.corners.topTrailing
            ? self.outerCornerRadius : self.innerCornerRadius,
          style: .continuous,
        ),
      )
  }

  private var tileContent: some View {
    CachedArtworkImageView(url: self.url) { image in
      image
        .resizable()
        .scaledToFill()
        .frame(width: self.size, height: self.size)
    } placeholder: {
      Rectangle()
        .fill(self.placeholderColor)
        .frame(width: self.size, height: self.size)
    }
  }

  private var placeholderColor: Color {
    switch self.index % 3 {
    case 0:
      Color(self.colorScheme, light: .slate200, dark: .slate700)
    case 1:
      Color(self.colorScheme, light: .slate300, dark: .slate800)
    default:
      Color(self.colorScheme, light: .slate400, dark: .slate900)
    }
  }
}

private struct PlaylistArtworkLayout {
  let tiles: [PlaylistArtworkTile]
  let columnCount: Int

  init(artworkUrls: [URL]) {
    var seen = Set<URL>()
    let uniqueArtworkUrls = artworkUrls.filter { seen.insert($0).inserted }
    let visibleTileCount: Int
    let columnCount: Int
    switch uniqueArtworkUrls.count {
    case 0:
      visibleTileCount = 0
      columnCount = 1
    case 1 ... 3:
      visibleTileCount = 1
      columnCount = 1
    case 4 ... 8:
      visibleTileCount = 4
      columnCount = 2
    default:
      visibleTileCount = 9
      columnCount = 3
    }

    self.columnCount = columnCount
    self.tiles = uniqueArtworkUrls.prefix(visibleTileCount).enumerated().map { index, artworkUrl in
      PlaylistArtworkTile(
        id: index,
        url: artworkUrl,
        corners: PlaylistArtworkTileCorners(
          index: index,
          columnCount: columnCount,
        ),
      )
    }
  }
}

private struct PlaylistArtworkTile: Identifiable {
  let id: Int
  let url: URL?
  let corners: PlaylistArtworkTileCorners
}

private struct PlaylistArtworkTileCorners {
  let topLeading: Bool
  let topTrailing: Bool
  let bottomLeading: Bool
  let bottomTrailing: Bool

  init(index: Int, columnCount: Int) {
    let row = index / columnCount
    let column = index % columnCount
    let lastPosition = columnCount - 1

    self.topLeading = row == 0 && column == 0
    self.topTrailing = row == 0 && column == lastPosition
    self.bottomLeading = row == lastPosition && column == 0
    self.bottomTrailing = row == lastPosition && column == lastPosition
  }
}

#if DEBUG
  #Preview("Empty playlist artwork") {
    PlaylistArtworkView(artworkUrls: [])
      .padding(24)
  }

  #Preview("Deduplicated playlist artwork") {
    PlaylistArtworkView(artworkUrls: Array(
      repeating: PreviewMusicData.storiesArtworkURL,
      count: 10,
    ).compactMap(\.self))
      .padding(24)
  }

  #Preview("Playlist artwork") {
    PlaylistArtworkView(artworkUrls: [
      PreviewMusicData.storiesArtworkURL,
      PreviewMusicData.brewedArtworkURL,
      PreviewMusicData.ruleOf3ArtworkURL,
      PreviewMusicData.frifotArtworkURL,
    ].compactMap(\.self))
      .padding(24)
  }
#endif
