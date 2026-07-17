import Foundation
import SwiftUI

struct GlowingArtworkImage<ArtworkShape: Shape, StrokeShape: Shape, Placeholder: View>: View {
  @Environment(\.colorScheme) private var colorScheme

  let url: URL?
  let size: CGFloat
  let artworkShape: ArtworkShape
  let strokeShape: StrokeShape
  @ViewBuilder let placeholder: Placeholder

  init(
    url: URL?,
    size: CGFloat,
    artworkShape: ArtworkShape,
    strokeShape: StrokeShape,
    @ViewBuilder placeholder: () -> Placeholder,
  ) {
    self.url = url
    self.size = size
    self.artworkShape = artworkShape
    self.strokeShape = strokeShape
    self.placeholder = placeholder()
  }

  var body: some View {
    CachedArtworkImageView(url: self.url) { image in
      ZStack {
        image
          .resizable()
          .scaledToFill()
          .frame(width: self.size, height: self.size)
          .clipShape(self.artworkShape)
          .blur(radius: self.glowBlurRadius)
          .opacity(0.32)
          .scaleEffect(1.04)
          .offset(y: self.glowOffset)

        image
          .resizable()
          .scaledToFill()
          .frame(width: self.size, height: self.size)
          .clipShape(self.artworkShape)
          .overlay {
            self.strokeShape
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
    } placeholder: {
      self.placeholder
    }
  }

  private var glowBlurRadius: CGFloat {
    min(12, max(6, self.size * 0.08))
  }

  private var glowOffset: CGFloat {
    min(2, self.size * 0.015)
  }
}
