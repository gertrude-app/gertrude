import SwiftUI

struct ArtworkImageView: View {
  @Environment(\.colorScheme) var cs

  let artworkUrl: URL?
  let showsArtwork: Bool
  let size: CGFloat
  let cornerRadius: CGFloat

  init(
    artworkUrl: URL?,
    showsArtwork: Bool = true,
    size: CGFloat,
    cornerRadius: CGFloat,
  ) {
    self.artworkUrl = artworkUrl
    self.showsArtwork = showsArtwork
    self.size = size
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    if self.showsArtwork {
      CachedArtworkImageView(url: self.artworkUrl) { image in
        self.artwork(image)
      } placeholder: {
        self.placeholderArtwork
      }
    } else {
      self.hiddenArtwork
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
                Color(self.cs, light: .white.opacity(0.5), dark: .white.opacity(0.2)),
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

  private var hiddenArtwork: some View {
    ZStack {
      RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
        .fill(self.placeholderColor)

      Image(systemName: "eye.slash.fill")
        .font(.system(size: self.hiddenArtworkIconSize, weight: .semibold))
        .foregroundStyle(self.hiddenArtworkForeground)
    }
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

  private var hiddenArtworkIconSize: CGFloat {
    min(30, self.size * 0.34)
  }

  private var placeholderColor: Color {
    Color(
      self.cs,
      light: Color(red: 0.90, green: 0.90, blue: 0.92),
      dark: Color(red: 0.14, green: 0.14, blue: 0.16),
    )
  }

  private var hiddenArtworkForeground: Color {
    Color(
      self.cs,
      light: Color(red: 0.58, green: 0.58, blue: 0.62),
      dark: Color(red: 0.46, green: 0.46, blue: 0.50),
    )
  }
}
