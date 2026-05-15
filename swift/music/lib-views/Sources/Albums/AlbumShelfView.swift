import SwiftUI

public struct AlbumShelfView: View {
  private let title: String
  private let albums: [AlbumData]
  private let onTitleTap: @MainActor @Sendable () -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "My albums",
    albums: [AlbumData],
    onTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.albums = albums
    self.onTitleTap = onTitleTap
    self.onAlbumTap = onAlbumTap
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ShelfHeaderView(
        title: self.title,
        accessibilityLabel: "Show all albums",
        onTap: self.onTitleTap,
      )

      if self.albums.isEmpty {
        EmptyAlbumShelfCard()
          .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: 16) {
            ForEach(self.albums) { album in
              AlbumCardView(album: album) {
                self.onAlbumTap(album.id)
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

#Preview("Album shelf") {
  ScrollView {
    AlbumShelfView(albums: .previewAlbums)
      .padding(.vertical, 24)
  }
  .background(.background)
}

#Preview("Long names") {
  ScrollView {
    AlbumShelfView(albums: .longNamePreviewAlbums)
      .padding(.vertical, 24)
  }
  .background(.background)
}

#Preview("Album shelf empty") {
  ScrollView {
    AlbumShelfView(albums: [])
      .padding(.vertical, 24)
  }
  .background(.background)
}
