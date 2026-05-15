import SwiftUI

public struct ArtistArtworkView: View {
  private let artworkUrl: URL?
  private let showsArtwork: Bool
  private let size: CGFloat

  public init(
    artworkUrl: URL?,
    showsArtwork: Bool = true,
    size: CGFloat = 148,
  ) {
    self.artworkUrl = artworkUrl
    self.showsArtwork = showsArtwork
    self.size = size
  }

  public init(
    artist: ArtistData,
    size: CGFloat = 148,
  ) {
    self.init(
      artworkUrl: artist.artworkUrl,
      showsArtwork: artist.showsArtwork,
      size: size,
    )
  }

  public var body: some View {
    ArtworkImageView(
      artworkUrl: self.artworkUrl,
      showsArtwork: self.showsArtwork,
      size: self.size,
      cornerRadius: self.size / 2,
    )
  }
}

#Preview("Artist artwork") {
  VStack(spacing: 24) {
    ArtistArtworkView(artist: [ArtistData].previewArtists[1])
    ArtistArtworkView(artist: [ArtistData].previewArtists[3])
    ArtistArtworkView(
      artist: ArtistData(
        id: "missing-artist-artwork",
        name: "Missing Artist Artwork",
      ),
    )
  }
  .padding(24)
}
