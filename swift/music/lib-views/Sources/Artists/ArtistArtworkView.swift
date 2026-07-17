import Foundation
import SwiftUI

public struct ArtistArtworkView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let artworkUrl: URL?
  private let size: CGFloat

  public init(
    artworkUrl: URL?,
    size: CGFloat = 148,
  ) {
    self.artworkUrl = artworkUrl
    self.size = size
  }

  public init(
    artist: ArtistData,
    size: CGFloat = 148,
  ) {
    self.init(
      artworkUrl: artist.artworkUrl,
      size: size,
    )
  }

  public var body: some View {
    GlowingArtworkImage(
      url: self.artworkUrl,
      size: self.size,
      artworkShape: Circle(),
      strokeShape: Circle(),
    ) {
      Circle()
        .fill(Color.artworkPlaceholder(in: self.colorScheme))
        .frame(width: self.size, height: self.size)
        .overlay {
          Image(systemName: "person.fill")
            .font(.system(size: self.placeholderIconSize, weight: .semibold))
            .foregroundStyle(Color(
              self.colorScheme,
              light: .black.opacity(0.32),
              dark: .white.opacity(0.42),
            ))
        }
    }
  }

  private var placeholderIconSize: CGFloat {
    max(24, self.size * 0.24)
  }
}
