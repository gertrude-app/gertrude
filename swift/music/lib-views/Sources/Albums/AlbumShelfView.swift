import SwiftUI

public struct AlbumShelfView: View {
  private let title: String
  private let albums: [AlbumData]
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let onTitleTap: @MainActor @Sendable () -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "My albums",
    albums: [AlbumData],
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.albums = albums
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
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

      if self.isLoading {
        AlbumShelfSkeletonView()
      } else if self.albums.isEmpty {
        EmptyAlbumShelfCard()
          .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: 16) {
            ForEach(self.albums) { album in
              AlbumCardView(album: album, transitionNamespace: self.transitionNamespace) {
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

private struct AlbumShelfSkeletonView: View {
  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top, spacing: 16) {
        ForEach(0..<5, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 10) {
            SkeletonBlock(width: 148, height: 148, cornerRadius: 20)

            VStack(alignment: .leading, spacing: 6) {
              SkeletonBlock(width: 132, height: 13, cornerRadius: 6)
              SkeletonBlock(width: 92, height: 11, cornerRadius: 5)
            }
          }
          .frame(width: 148, alignment: .leading)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 4)
    }
    .scrollIndicators(.hidden)
    .scrollClipDisabled()
    .accessibilityLabel("Loading albums")
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

#Preview("Album shelf loading") {
  ScrollView {
    AlbumShelfView(albums: [], isLoading: true)
      .padding(.vertical, 24)
  }
  .background(.background)
}
