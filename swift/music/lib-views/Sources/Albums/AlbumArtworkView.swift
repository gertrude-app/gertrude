import Foundation
import SwiftUI

public func albumArtworkZoomTransitionID(for albumID: String) -> String {
  "album-artwork-\(albumID)"
}

public struct AlbumArtworkView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let artworkUrl: URL?
  private let size: CGFloat
  private let cornerRadius: CGFloat

  public init(
    artworkUrl: URL?,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 12,
  ) {
    self.artworkUrl = artworkUrl
    self.size = size
    self.cornerRadius = cornerRadius
  }

  public init(
    album: AlbumData,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 12,
  ) {
    self.init(
      artworkUrl: album.artworkUrl,
      size: size,
      cornerRadius: cornerRadius,
    )
  }

  public var body: some View {
    GlowingArtworkImage(
      url: self.artworkUrl,
      size: self.size,
      artworkShape: RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous),
      strokeShape: RoundedRectangle(cornerRadius: self.strokeCornerRadius, style: .continuous),
    ) {
      RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
        .fill(Color.artworkPlaceholder(in: self.colorScheme))
        .frame(width: self.size, height: self.size)
    }
  }

  private var strokeCornerRadius: CGFloat {
    max(0, self.cornerRadius - 1)
  }
}

#if DEBUG
  #Preview("Album artwork") {
    VStack(spacing: 24) {
      AlbumArtworkView(album: [AlbumData].previewAlbums[0])
      AlbumArtworkView(album: [AlbumData].previewAlbums[1])
      AlbumArtworkView(
        album: AlbumData(
          id: "missing-artwork",
          title: "Missing Artwork",
          artist: "Preview",
        ),
      )
    }
    .padding(24)
  }
#endif
