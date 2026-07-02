import SwiftUI

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
    CachedArtworkImageView(url: self.artworkUrl) { image in
      self.artwork(image)
    } placeholder: {
      self.placeholderArtwork
    }
  }

  private func artwork(_ image: Image) -> some View {
    ZStack {
      image
        .resizable()
        .scaledToFill()
        .frame(width: self.size, height: self.size)
        .clipShape(.rect(cornerRadius: self.cornerRadius, style: .continuous))
        .blur(radius: self.glowBlurRadius)
        .opacity(0.32)
        .scaleEffect(1.04)
        .offset(y: self.glowOffset)

      image
        .resizable()
        .scaledToFill()
        .frame(width: self.size, height: self.size)
        .clipShape(.rect(cornerRadius: self.cornerRadius, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: self.strokeCornerRadius, style: .continuous)
            .stroke(
              Gradient(colors: [
                Color(self.colorScheme, light: .white.opacity(0.5), dark: .white.opacity(0.2)),
                .clear,
                .black.opacity(0.1),
              ]),
              lineWidth: 1.5,
            )
            .frame(width: self.size - 0.75, height: self.size - 0.75)
        }
    }
    .frame(width: self.size, height: self.size)
  }

  private var placeholderArtwork: some View {
    RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
      .fill(self.placeholderColor)
      .frame(width: self.size, height: self.size)
  }

  private var strokeCornerRadius: CGFloat {
    max(0, self.cornerRadius - 1)
  }

  private var glowBlurRadius: CGFloat {
    min(12, max(6, self.size * 0.08))
  }

  private var glowOffset: CGFloat {
    min(2, self.size * 0.015)
  }

  private var placeholderColor: Color {
    Color(
      self.colorScheme,
      light: Color(red: 0.90, green: 0.90, blue: 0.92),
      dark: Color(red: 0.14, green: 0.14, blue: 0.16),
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
