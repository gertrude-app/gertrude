import SwiftUI

public struct ArtistShelfView: View {
  private let title: String
  private let artists: [ArtistData]
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let onTitleTap: @MainActor @Sendable () -> Void
  private let onArtistTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "My artists",
    artists: [ArtistData],
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
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

      if self.isLoading {
        ArtistShelfSkeletonView()
      } else if self.artists.isEmpty {
        EmptyArtistShelfCard()
          .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: 16) {
            ForEach(self.artists) { artist in
              ArtistCardView(artist: artist, transitionNamespace: self.transitionNamespace) {
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

private struct ArtistShelfSkeletonView: View {
  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top, spacing: 16) {
        ForEach(0 ..< 5, id: \.self) { _ in
          VStack(alignment: .center, spacing: 10) {
            SkeletonBlock(width: 148, height: 148, cornerRadius: 74)
            SkeletonBlock(width: 112, height: 13, cornerRadius: 6)
          }
          .frame(width: 148, alignment: .center)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 4)
    }
    .scrollIndicators(.hidden)
    .scrollClipDisabled()
    .accessibilityLabel("Loading artists")
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

#Preview("Artist shelf loading") {
  ScrollView {
    ArtistShelfView(artists: [], isLoading: true)
      .padding(.vertical, 24)
  }
  .background(.background)
}
