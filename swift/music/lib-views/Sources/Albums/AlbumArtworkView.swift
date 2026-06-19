import SwiftUI

public struct AlbumArtworkView: View {
  private let artworkUrl: URL?
  private let showsArtwork: Bool
  private let size: CGFloat
  private let cornerRadius: CGFloat

  public init(
    artworkUrl: URL?,
    showsArtwork: Bool = true,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 20,
  ) {
    self.artworkUrl = artworkUrl
    self.showsArtwork = showsArtwork
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
      showsArtwork: album.showsArtwork,
      size: size,
      cornerRadius: cornerRadius,
    )
  }

  public var body: some View {
    ArtworkImageView(
      artworkUrl: self.artworkUrl,
      showsArtwork: self.showsArtwork,
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
