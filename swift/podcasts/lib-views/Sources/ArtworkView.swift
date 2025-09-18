import LibCore
import SwiftUI

public struct ArtworkView: View {
  @Environment(\.colorScheme) var cs

  let artworkImage: UIImage?
  let artworkUrl: String?
  let placeholderIconSize: CGFloat

  public init(
    artworkImage: UIImage? = nil,
    artworkUrl: String? = nil,
    placeholderIconSize: CGFloat = 20
  ) {
    self.artworkImage = artworkImage
    self.artworkUrl = artworkUrl
    self.placeholderIconSize = placeholderIconSize
  }

  public var body: some View {
    Group {
      if let artworkImage {
        Image(uiImage: artworkImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else if let artworkUrl, let url = URL(string: artworkUrl) {
        AsyncImage(url: url) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          self.artworkPlaceholder
        }
      } else {
        self.artworkPlaceholder
      }
    }
  }

  private var artworkPlaceholder: some View {
    Rectangle()
      .fill(Color(self.cs, light: .violet200, dark: .violet800))
      .overlay(
        Image(systemName: "mic")
          .font(.system(size: self.placeholderIconSize, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet500))
      )
  }
}

#Preview("With URL") {
  ArtworkView(
    artworkUrl: "https://example.com/artwork.jpg",
    placeholderIconSize: 40
  )
  .frame(width: 100, height: 100)
  .cornerRadius(8)
}

#Preview("Placeholder") {
  ArtworkView(placeholderIconSize: 40)
    .frame(width: 100, height: 100)
    .cornerRadius(8)
}

#Preview("Dark Mode") {
  ArtworkView(placeholderIconSize: 40)
    .frame(width: 100, height: 100)
    .cornerRadius(8)
    .preferredColorScheme(.dark)
}
