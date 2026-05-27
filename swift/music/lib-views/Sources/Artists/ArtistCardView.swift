import SwiftUI

public struct ArtistCardView: View {
  @Environment(\.colorScheme) var cs

  private let artist: ArtistData
  private let artworkSize: CGFloat
  private let transitionNamespace: Namespace.ID?
  private let onTap: @MainActor @Sendable () -> Void

  public init(
    artist: ArtistData,
    artworkSize: CGFloat = 148,
    transitionNamespace: Namespace.ID? = nil,
    onTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.artist = artist
    self.artworkSize = artworkSize
    self.transitionNamespace = transitionNamespace
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: self.onTap) {
      VStack(alignment: .center, spacing: 10) {
        ArtistArtworkView(artist: self.artist, size: self.artworkSize)

        Text(self.artist.name)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(
            Color(self.cs, light: .black, dark: .white)
          )
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }
      .frame(width: self.artworkSize, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.artist.name)
    .matchedTransitionSourceIfAvailable(id: self.artist.id, in: self.transitionNamespace)
  }
}

#Preview("Artist cards") {
  HStack(alignment: .top, spacing: 16) {
    ArtistCardView(artist: [ArtistData].previewArtists[1])
    ArtistCardView(artist: [ArtistData].previewArtists[3])
  }
  .padding(24)
}
