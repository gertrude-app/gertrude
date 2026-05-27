import SwiftUI

public struct ArtistListView: View {
  private let title: String
  private let artists: [ArtistData]
  private let transitionNamespace: Namespace.ID?
  private let onArtistTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "Artists",
    artists: [ArtistData],
    transitionNamespace: Namespace.ID? = nil,
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.artists = artists.sorted { lhs, rhs in
      lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
    self.transitionNamespace = transitionNamespace
    self.onArtistTap = onArtistTap
  }

  public var body: some View {
    GeometryReader { proxy in
      ScrollView {
        if self.artists.isEmpty {
          ArtistListEmptyStateView()
            .padding(.horizontal, self.horizontalPadding)
            .padding(.top, 24)
        } else {
          LazyVGrid(columns: self.columns, alignment: .leading, spacing: 24) {
            ForEach(self.artists) { artist in
              ArtistCardView(
                artist: artist,
                artworkSize: self.artworkSize(for: proxy.size.width),
                transitionNamespace: self.transitionNamespace,
              ) {
                self.onArtistTap(artist.id)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .padding(.horizontal, self.horizontalPadding)
          .padding(.vertical, 16)
        }
      }
      .background(.background)
    }
    .navigationTitle(self.title)
  }

  private let horizontalPadding: CGFloat = 20
  private let columnSpacing: CGFloat = 16

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(minimum: 148), spacing: self.columnSpacing, alignment: .top),
      count: 2,
    )
  }

  private func artworkSize(for containerWidth: CGFloat) -> CGFloat {
    max(148, floor((containerWidth - self.horizontalPadding * 2 - self.columnSpacing) / 2))
  }
}

private struct ArtistListEmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "music.mic")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(.secondary)

      Text("No artists yet")
        .font(.system(size: 18, weight: .semibold))

      Text("Approved artists will show up here.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
  }
}

#Preview("Artist list") {
  NavigationStack {
    ArtistListView(artists: .previewArtists)
  }
}

#Preview("Artist list empty") {
  NavigationStack {
    ArtistListView(artists: [])
  }
}
