import SwiftUI

public struct AlbumListView: View {
  private let title: String
  private let albums: [AlbumData]
  private let transitionNamespace: Namespace.ID?
  private let onAlbumTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "Albums",
    albums: [AlbumData],
    transitionNamespace: Namespace.ID? = nil,
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.albums = albums
    self.transitionNamespace = transitionNamespace
    self.onAlbumTap = onAlbumTap
  }

  public var body: some View {
    GeometryReader { proxy in
      ScrollView {
        if self.albums.isEmpty {
          AlbumListEmptyStateView()
            .padding(.horizontal, self.horizontalPadding)
            .padding(.top, 24)
        } else {
          LazyVGrid(columns: self.columns, alignment: .leading, spacing: 24) {
            ForEach(self.albums) { album in
              AlbumCardView(
                album: album,
                artworkSize: self.artworkSize(for: proxy.size.width),
                transitionNamespace: self.transitionNamespace,
              ) {
                self.onAlbumTap(album.id)
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

private struct AlbumListEmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "rectangle.stack")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(.secondary)

      Text("No albums yet")
        .font(.system(size: 18, weight: .semibold))

      Text("Approved albums will show up here.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
  }
}

#Preview("Album list") {
  NavigationStack {
    AlbumListView(albums: .previewAlbums)
  }
}

#Preview("Album list empty") {
  NavigationStack {
    AlbumListView(albums: [])
  }
}
