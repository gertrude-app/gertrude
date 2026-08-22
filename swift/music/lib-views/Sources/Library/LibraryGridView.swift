import GertieUI
import SwiftUI

struct LibraryGridView: View {
  private let items: [LibraryCollectionItemData]
  private let playingItemID: String?
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let onAlbumAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onAlbumAddToQueue: @MainActor @Sendable (String) -> Void
  private let onAlbumPlayNext: @MainActor @Sendable (String) -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onArtistAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onArtistAddToQueue: @MainActor @Sendable (String) -> Void
  private let onArtistPlayNext: @MainActor @Sendable (String) -> Void
  private let onArtistTap: @MainActor @Sendable (String) -> Void
  private let onPlaylistAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onPlaylistAddToQueue: @MainActor @Sendable (String) -> Void
  private let onPlaylistPlayNext: @MainActor @Sendable (String) -> Void
  private let onPlaylistTap: @MainActor @Sendable (String) -> Void
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  @State private var filter: LibraryFilter?

  init(
    items: [LibraryCollectionItemData],
    playingItemID: String? = nil,
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onAlbumAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlaylistAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlaylistAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlaylistPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlaylistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.items = items
    self.playingItemID = playingItemID
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
    self.onAlbumAddToPlaylist = onAlbumAddToPlaylist
    self.onAlbumAddToQueue = onAlbumAddToQueue
    self.onAlbumPlayNext = onAlbumPlayNext
    self.onAlbumTap = onAlbumTap
    self.onArtistAddToPlaylist = onArtistAddToPlaylist
    self.onArtistAddToQueue = onArtistAddToQueue
    self.onArtistPlayNext = onArtistPlayNext
    self.onArtistTap = onArtistTap
    self.onPlaylistAddToPlaylist = onPlaylistAddToPlaylist
    self.onPlaylistAddToQueue = onPlaylistAddToQueue
    self.onPlaylistPlayNext = onPlaylistPlayNext
    self.onPlaylistTap = onPlaylistTap
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
        } else if self.items.isEmpty {
          LibraryGridEmptyStateView()
            .padding(.horizontal, self.horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, self.bottomContentPadding)
        } else {
          LibraryFilterPills(selection: self.$filter)
            .padding(.horizontal, self.horizontalPadding)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
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

  private var filteredItems: [LibraryCollectionItemData] {
    self.items.filter { $0.isIncluded(in: self.filter) }
  }

  @ViewBuilder
  private func libraryGrid(metrics: LibraryGridMetrics) -> some View {
    if let filter = self.filter, self.filteredItems.isEmpty {
      LibraryFilteredEmptyStateView(filter: filter)
        .padding(.horizontal, self.horizontalPadding)
        .padding(.top, 24)
        .padding(.bottom, self.bottomContentPadding)
    } else {
      LazyVGrid(columns: metrics.columns, alignment: .leading, spacing: 24) {
        ForEach(self.filteredItems) { item in
          switch item {
          case .album(let album):
            AlbumCardView(
              album: album,
              artworkSize: metrics.artworkSize,
              isPlaying: item.id == self.playingItemID,
              transitionNamespace: self.transitionNamespace,
              onAddToPlaylist: { self.onAlbumAddToPlaylist(album.id) },
              onAddToQueue: { self.onAlbumAddToQueue(album.id) },
              onPlayNext: { self.onAlbumPlayNext(album.id) },
            ) {
              self.onAlbumTap(album.id)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

          case .artist(let artist):
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
            .playbackQueueContextMenu(
              onPlayNext: { self.onArtistPlayNext(artist.id) },
              onAddToQueue: { self.onArtistAddToQueue(artist.id) },
              onAddToPlaylist: { self.onArtistAddToPlaylist(artist.id) },
            )
            .frame(maxWidth: .infinity, alignment: .leading)

          case .playlist(let playlist):
            PlaylistCardView(
              playlist: playlist,
              artworkSize: metrics.artworkSize,
              isPlaying: item.id == self.playingItemID,
              transitionNamespace: self.transitionNamespace,
              onAddToPlaylist: { self.onPlaylistAddToPlaylist(playlist.id) },
              onAddToQueue: { self.onPlaylistAddToQueue(playlist.id) },
              onPlayNext: { self.onPlaylistPlayNext(playlist.id) },
              onTap: { self.onPlaylistTap(playlist.id) },
            )
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .frame(width: metrics.contentWidth, alignment: .leading)
      .padding(.horizontal, self.horizontalPadding)
      .frame(maxWidth: .infinity)
      .padding(.top, 16)
      .padding(.bottom, self.itemGridBottomPadding)
    }
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

  private var itemGridBottomPadding: CGFloat {
    #if DEBUG
      self.onDebugResetTap == nil ? self.bottomContentPadding : 8
    #else
      self.bottomContentPadding
    #endif
  }
}

struct LibraryCardMetadataView: View {
  let title: String
  let subtitle: String
  let isPlaying: Bool
  let titleColor: Color
  let subtitleColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .top, spacing: 6) {
        Text(self.title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(
            self.isPlaying ? Color.gertrudeBrandAccent : self.titleColor,
          )
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .layoutPriority(1)

        if self.isPlaying {
          Spacer(minLength: 4)

          PlaybackWaveformView(
            isPlaying: true,
            color: .gertrudeBrandAccent,
            barCount: 4,
            barWidth: 2.5,
            barSpacing: 1.5,
            minimumBarHeight: 3,
            maximumBarHeight: 14,
            containerWidth: 16,
            containerHeight: 16,
            alignment: .center,
            phaseStep: 0.85,
            minimumInterval: 1.0 / 15.0,
          )
          .padding(.top, 1)
          .accessibilityHidden(true)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(self.subtitle)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(
          self.isPlaying
            ? Color.gertrudeBrandAccent.opacity(0.68)
            : self.subtitleColor,
        )
        .lineLimit(1)
    }
  }
}

private struct LibraryFilterPills: View {
  @Binding private var selection: LibraryFilter?

  init(selection: Binding<LibraryFilter?>) {
    self._selection = selection
  }

  var body: some View {
    if #available(iOS 26.0, macOS 26.0, *) {
      GlassEffectContainer(spacing: 8) {
        HStack(spacing: 8) {
          ForEach(LibraryFilter.allCases, id: \.self) { filter in
            LibraryGlassFilterButton(
              filter: filter,
              selection: self.$selection,
            )
          }
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Library filters")
    } else {
      HStack(spacing: 8) {
        ForEach(LibraryFilter.allCases, id: \.self) { filter in
          LibraryMaterialFilterButton(
            filter: filter,
            selection: self.$selection,
          )
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Library filters")
    }
  }
}

@available(iOS 26.0, macOS 26.0, *)
private struct LibraryGlassFilterButton: View {
  let filter: LibraryFilter
  @Binding var selection: LibraryFilter?

  var body: some View {
    Button(action: self.buttonTapped) {
      Text(self.filter.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
    .buttonStyle(.plain)
    .glassEffect(
      self.isSelected
        ? .regular.tint(Color.gertrudeBrandAccent.opacity(0.42)).interactive()
        : .regular.interactive(),
      in: .capsule,
    )
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    .accessibilityHint(self.accessibilityHint)
  }

  private var isSelected: Bool {
    self.selection == self.filter
  }

  private var accessibilityHint: String {
    self.isSelected
      ? "Double-tap to show all music"
      : "Double-tap to show only \(self.filter.title.lowercased())"
  }

  private func buttonTapped() {
    withAnimation(.smooth) {
      self.selection = self.isSelected ? nil : self.filter
    }
  }
}

private struct LibraryMaterialFilterButton: View {
  let filter: LibraryFilter
  @Binding var selection: LibraryFilter?

  var body: some View {
    Button(action: self.buttonTapped) {
      Text(self.filter.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
    .buttonStyle(.plain)
    .background(
      self.isSelected
        ? Color.gertrudeBrandAccent.opacity(0.32)
        : Color.primary.opacity(0.08),
      in: .capsule,
    )
    .overlay {
      Capsule()
        .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
    }
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    .accessibilityHint(self.accessibilityHint)
  }

  private var isSelected: Bool {
    self.selection == self.filter
  }

  private var accessibilityHint: String {
    self.isSelected
      ? "Double-tap to show all music"
      : "Double-tap to show only \(self.filter.title.lowercased())"
  }

  private func buttonTapped() {
    withAnimation(.smooth) {
      self.selection = self.isSelected ? nil : self.filter
    }
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

      Text("Approved artists, albums, and your playlists will show up here.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
    .frame(maxWidth: 600)
    .frame(maxWidth: .infinity)
  }
}

private struct LibraryFilteredEmptyStateView: View {
  let filter: LibraryFilter

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: self.systemImage)
        .font(.system(size: 28, weight: .semibold))
        .foregroundStyle(.secondary)

      Text("No \(self.filter.title.lowercased()) yet")
        .font(.system(size: 17, weight: .semibold))
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
    .frame(maxWidth: 600)
    .frame(maxWidth: .infinity)
  }

  private var systemImage: String {
    switch self.filter {
    case .playlists:
      "music.note.list"
    case .artists:
      "music.mic"
    case .albums:
      "square.stack"
    }
  }
}

#if DEBUG
  private let previewLibraryItems: [LibraryCollectionItemData] =
    [PlaylistData.previewRoadTrip].map(LibraryCollectionItemData.playlist)
      + [ArtistData].previewArtists.map(LibraryCollectionItemData.artist)
      + [AlbumData].previewAlbums.map(LibraryCollectionItemData.album)

  #Preview("Library grid") {
    LibraryGridView(items: previewLibraryItems, onDebugResetTap: {})
  }

  #Preview("Library grid empty") {
    LibraryGridView(items: [])
  }

  #Preview("Library grid narrow") {
    LibraryGridView(items: previewLibraryItems)
      .frame(width: 320, height: 568)
  }

  #Preview("Library grid wide") {
    LibraryGridView(items: previewLibraryItems)
      .frame(width: 1024, height: 768)
  }

  #Preview("Library filter selected") {
    @Previewable @State var filter: LibraryFilter? = .playlists
    LibraryFilterPills(selection: $filter)
      .padding()
      .preferredColorScheme(.dark)
  }
#endif
