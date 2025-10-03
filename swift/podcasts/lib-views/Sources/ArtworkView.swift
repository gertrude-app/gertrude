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
  let size: CGFloat
  let cornerRadius: CGFloat

  public init(
    preferRemote: Bool = false,
    artworkImage: UIImage? = nil,
    artworkUrl: String? = nil,
    size: CGFloat,
    cornerRadius: CGFloat = 6
  ) {
    self.preferRemote = preferRemote
    self.artworkImage = artworkImage
    self.artworkUrl = artworkUrl
    self.size = size
    self.cornerRadius = cornerRadius
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
    .frame(width: self.size, height: self.size)
    .cornerRadius(self.cornerRadius)
    .clipped()
  }

  private var artworkPlaceholder: some View {
    Image("artwork")
      .resizable()
      .aspectRatio(contentMode: .fill)
  }
}

@MainActor
protocol EpisodeArtworkProvider {
  var episode: EpisodeData { get }
  var show: ShowData { get }
}

extension EpisodeArtworkProvider {
  var useEpisodeArtwork: Bool {
    self.episode.artworkUrl != nil && self.show.showArtwork
  }

  var artworkUrl: String? {
    self.show.showArtwork
      ? (self.episode.artworkUrl ?? self.show.artworkUrl)
      : nil
  }
}

extension ArtworkView {
  init(provider: some EpisodeArtworkProvider, size: CGFloat, cornerRadius: CGFloat = 6) {
    self.init(
      preferRemote: provider.useEpisodeArtwork,
      artworkImage: provider.show.showArtwork ? provider.show.artworkImage : nil,
      artworkUrl: provider.show.showArtwork ? provider.artworkUrl : nil,
      size: size,
      cornerRadius: cornerRadius
    )
  }
}

#Preview("With URL") {
  ArtworkView(
    artworkUrl: "https://example.com/artwork.jpg",
    size: 100
  )
}

#Preview("Placeholder") {
  ArtworkView(size: 100)
}

#Preview("Dark Mode") {
  ArtworkView(size: 100)
    .preferredColorScheme(.dark)
}
