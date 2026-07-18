import SwiftUI

struct LibraryGridView: View {
  private let albums: [AlbumData]
  private let artists: [ArtistData]
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let onAlbumAddToQueue: @MainActor @Sendable (String) -> Void
  private let onAlbumPlayNext: @MainActor @Sendable (String) -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onArtistTap: @MainActor @Sendable (String) -> Void
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  init(
    albums: [AlbumData],
    artists: [ArtistData] = [],
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onAlbumAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.albums = albums
    self.artists = artists
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
    self.onAlbumAddToQueue = onAlbumAddToQueue
    self.onAlbumPlayNext = onAlbumPlayNext
    self.onAlbumTap = onAlbumTap
    self.onArtistTap = onArtistTap
    self.onDebugResetTap = onDebugResetTap
  }

  var body: some View {
    GeometryReader { proxy in
      let metrics = LibraryGridMetrics(
        containerWidth: proxy.size.width,
        horizontalPadding: self.horizontalPadding,
        columnSpacing: self.columnSpacing,
      )

      ScrollView {
        if self.isLoading {
          self.loadingGrid(metrics: metrics)
        } else if self.albums.isEmpty, self.artists.isEmpty {
          LibraryGridEmptyStateView()
            .padding(.horizontal, self.horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, self.bottomContentPadding)
        } else {
          self.libraryGrid(metrics: metrics)

          #if DEBUG
            if let onDebugResetTap = self.onDebugResetTap {
              DebugResetOnboardingButton(onTap: onDebugResetTap)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, self.horizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, self.bottomContentPadding)
            }
          #endif
        }
      }
      .background(.background)
    }
  }

  private let horizontalPadding: CGFloat = 20
  private let columnSpacing: CGFloat = 16

  private func libraryGrid(metrics: LibraryGridMetrics) -> some View {
    LazyVGrid(columns: metrics.columns, alignment: .leading, spacing: 24) {
      ForEach(self.artists) { artist in
        Button {
          self.onArtistTap(artist.id)
        } label: {
          ArtistCardView(
            artist: artist,
            artworkSize: metrics.artworkSize,
            transitionNamespace: self.transitionNamespace,
          )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      ForEach(self.albums) { album in
        AlbumCardView(
          album: album,
          artworkSize: metrics.artworkSize,
          transitionNamespace: self.transitionNamespace,
          onAddToQueue: { self.onAlbumAddToQueue(album.id) },
          onPlayNext: { self.onAlbumPlayNext(album.id) },
        ) {
          self.onAlbumTap(album.id)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(width: metrics.contentWidth, alignment: .leading)
    .padding(.horizontal, self.horizontalPadding)
    .frame(maxWidth: .infinity)
    .padding(.top, 16)
    .padding(.bottom, self.albumGridBottomPadding)
  }

  private func loadingGrid(metrics: LibraryGridMetrics) -> some View {
    LazyVGrid(columns: metrics.columns, alignment: .leading, spacing: 24) {
      ForEach(0 ..< 6, id: \.self) { _ in
        VStack(alignment: .leading, spacing: 10) {
          SkeletonBlock(
            width: metrics.artworkSize,
            height: metrics.artworkSize,
            cornerRadius: 20,
          )

          VStack(alignment: .leading, spacing: 6) {
            SkeletonBlock(width: min(132, metrics.artworkSize), height: 13, cornerRadius: 6)
            SkeletonBlock(width: min(92, metrics.artworkSize), height: 11, cornerRadius: 5)
          }
        }
        .frame(width: metrics.artworkSize, alignment: .leading)
      }
    }
    .frame(width: metrics.contentWidth, alignment: .leading)
    .padding(.horizontal, self.horizontalPadding)
    .frame(maxWidth: .infinity)
    .padding(.top, 16)
    .padding(.bottom, self.bottomContentPadding)
    .accessibilityLabel("Loading library")
  }

  private let bottomContentPadding: CGFloat = 96

  private var albumGridBottomPadding: CGFloat {
    #if DEBUG
      self.onDebugResetTap == nil ? self.bottomContentPadding : 8
    #else
      self.bottomContentPadding
    #endif
  }
}

private struct LibraryGridMetrics {
  let artworkSize: CGFloat
  let columns: [GridItem]
  let contentWidth: CGFloat

  init(
    containerWidth: CGFloat,
    horizontalPadding: CGFloat,
    columnSpacing: CGFloat,
  ) {
    let availableWidth = max(1, containerWidth - horizontalPadding * 2)
    let minimumArtworkSize: CGFloat = 148
    let maximumArtworkSize: CGFloat = 220
    let maximumColumnCount = 5
    let fittingColumnCount = max(
      1,
      Int(floor((availableWidth + columnSpacing) / (minimumArtworkSize + columnSpacing))),
    )
    let columnCount = min(maximumColumnCount, fittingColumnCount)
    let totalSpacing = CGFloat(columnCount - 1) * columnSpacing
    let uncappedArtworkSize = floor((availableWidth - totalSpacing) / CGFloat(columnCount))
    let artworkSize = max(1, min(maximumArtworkSize, uncappedArtworkSize))

    self.artworkSize = artworkSize
    self.columns = Array(
      repeating: GridItem(.fixed(artworkSize), spacing: columnSpacing, alignment: .top),
      count: columnCount,
    )
    self.contentWidth = artworkSize * CGFloat(columnCount) + totalSpacing
  }
}

private struct LibraryGridEmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "rectangle.stack")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(.secondary)

      Text("No music yet")
        .font(.system(size: 18, weight: .semibold))

      Text("Approved artists and albums will show up here.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
    .frame(maxWidth: 600)
    .frame(maxWidth: .infinity)
  }
}

#if DEBUG
  #Preview("Library grid") {
    LibraryGridView(albums: .previewAlbums, artists: .previewArtists, onDebugResetTap: {})
  }

  #Preview("Library grid empty") {
    LibraryGridView(albums: [])
  }

  #Preview("Library grid narrow") {
    LibraryGridView(albums: .previewAlbums, artists: .previewArtists)
      .frame(width: 320, height: 568)
  }

  #Preview("Library grid wide") {
    LibraryGridView(albums: .previewAlbums, artists: .previewArtists)
      .frame(width: 1024, height: 768)
  }
#endif
