import SwiftUI

public struct AlbumArtworkView: View {
  private let artworkUrl: URL?
  private let size: CGFloat
  private let cornerRadius: CGFloat

  public init(
    artworkUrl: URL?,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 20,
  ) {
    self.artworkUrl = artworkUrl
    self.size = size
    self.cornerRadius = cornerRadius
  }

  public init(
    album: AlbumData,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 20,
  ) {
    self.init(
      artworkUrl: album.artworkUrl,
      size: size,
      cornerRadius: cornerRadius,
    )
  }

  public var body: some View {
    ArtworkImageView(
      artworkUrl: self.artworkUrl,
      size: self.size,
      cornerRadius: self.cornerRadius,
    )
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
