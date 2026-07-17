import SwiftUI

public func artistArtworkZoomTransitionID(for artistID: String) -> String {
  "artist-artwork-\(artistID)"
}

public struct ArtistCardView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let artist: ArtistData
  private let artworkSize: CGFloat
  private let transitionNamespace: Namespace.ID?

  public init(
    artist: ArtistData,
    artworkSize: CGFloat = 148,
    transitionNamespace: Namespace.ID? = nil,
  ) {
    self.artist = artist
    self.artworkSize = artworkSize
    self.transitionNamespace = transitionNamespace
  }

  public var body: some View {
    VStack(alignment: .center, spacing: 10) {
      ArtistArtworkView(
        artworkUrl: self.artist.artworkUrl,
        size: self.artworkSize,
      )
      .matchedTransitionSourceIfAvailable(
        id: self.artworkTransitionID,
        in: self.transitionNamespace,
      )

      Text(self.artist.name)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(self.colorScheme, light: .black, dark: .white))
        .lineLimit(2)
        .multilineTextAlignment(.center)
    }
    .frame(width: self.artworkSize, alignment: .center)
    .contentShape(Rectangle())
    .accessibilityLabel("\(self.artist.name), artist")
  }

  private var artworkTransitionID: String {
    artistArtworkZoomTransitionID(for: self.artist.id)
  }
}

#if DEBUG
  #Preview("Artist card") {
    HStack(alignment: .top, spacing: 16) {
      ArtistCardView(artist: [ArtistData].previewArtists[0])
      ArtistCardView(artist: [ArtistData].previewArtists[1])
    }
    .padding(24)
  }
#endif
