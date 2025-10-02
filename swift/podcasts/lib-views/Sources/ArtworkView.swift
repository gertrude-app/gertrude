import SwiftUI

#if canImport(UIKit)
  import UIKit
#else
  import LibCore
#endif

public struct ArtworkView: View {
  @Environment(\.colorScheme) var cs

  let preferRemote: Bool
  let artworkImage: UIImage?
  let artworkUrl: String?
  let placeholderIconSize: CGFloat

  public init(
    preferRemote: Bool = false,
    artworkImage: UIImage? = nil,
    artworkUrl: String? = nil,
    placeholderIconSize: CGFloat = 20
  ) {
    self.preferRemote = preferRemote
    self.artworkImage = artworkImage
    self.artworkUrl = artworkUrl
    self.placeholderIconSize = placeholderIconSize
  }

  public var body: some View {
    Group {
      if self.preferRemote, let artworkUrl, let url = URL(string: artworkUrl) {
        AsyncImage(url: url) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          if let artworkImage {
            Image(uiImage: artworkImage)
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            self.artworkPlaceholder
          }
        }
      } else {
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
  }

  private var artworkPlaceholder: some View {
    Image("artwork")
      .resizable()
      .aspectRatio(contentMode: .fill)
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
