import SwiftUI

public struct ArtistShelfView: View {
  private let title: String
  private let artists: [ArtistData]
  private let onTitleTap: @MainActor @Sendable () -> Void
  private let onArtistTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "My artists",
    artists: [ArtistData],
    onTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.artists = artists.sorted { lhs, rhs in
      lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
    self.onTitleTap = onTitleTap
    self.onArtistTap = onArtistTap
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ShelfHeaderView(
        title: self.title,
        accessibilityLabel: "Show all artists",
        onTap: self.onTitleTap,
      )

      if self.artists.isEmpty {
        EmptyArtistShelfCard()
          .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: 16) {
            ForEach(self.artists) { artist in
              ArtistCardView(artist: artist) {
                self.onArtistTap(artist.id)
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
      }
    }
  }
}

#Preview("Artist shelf") {
  ScrollView {
    ArtistShelfView(artists: .previewArtists)
      .padding(.vertical, 24)
  }
  .background(.background)
}

#Preview("Artist shelf empty") {
  ScrollView {
    ArtistShelfView(artists: [])
      .padding(.vertical, 24)
  }
  .background(.background)
}
