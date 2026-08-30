import GertieUI
import SwiftUI

struct LibraryGridView: View {
  private let items: [LibraryCollectionItemData]
  private let playingItemID: String?
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let albumActions: LibraryItemActions
  private let artistActions: LibraryItemActions
  private let playlistActions: LibraryItemActions
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  @State private var filter: LibraryFilter?

  init(
    items: [LibraryCollectionItemData],
    playingItemID: String? = nil,
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    albumActions: LibraryItemActions = .init(),
    artistActions: LibraryItemActions = .init(),
    playlistActions: LibraryItemActions = .init(),
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.items = items
    self.playingItemID = playingItemID
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
    self.albumActions = albumActions
    self.artistActions = artistActions
    self.playlistActions = playlistActions
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
              onAddToPlaylist: { self.albumActions.onAddToPlaylist(album.id) },
              onAddToQueue: { self.albumActions.onAddToQueue(album.id) },
              onPlayNext: { self.albumActions.onPlayNext(album.id) },
            ) {
              self.albumActions.onTap(album.id)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

          case .artist(let artist):
            Button {
              self.artistActions.onTap(artist.id)
            } label: {
              ArtistCardView(
                artist: artist,
                artworkSize: metrics.artworkSize,
                transitionNamespace: self.transitionNamespace,
              )
            }
            .buttonStyle(.plain)
            .playbackQueueContextMenu(
              onPlayNext: { self.artistActions.onPlayNext(artist.id) },
              onAddToQueue: { self.artistActions.onAddToQueue(artist.id) },
              onAddToPlaylist: { self.artistActions.onAddToPlaylist(artist.id) },
            )
            .frame(maxWidth: .infinity, alignment: .leading)

          case .playlist(let playlist):
            PlaylistCardView(
              playlist: playlist,
              artworkSize: metrics.artworkSize,
              isPlaying: item.id == self.playingItemID,
              transitionNamespace: self.transitionNamespace,
              onAddToPlaylist: { self.playlistActions.onAddToPlaylist(playlist.id) },
              onAddToQueue: { self.playlistActions.onAddToQueue(playlist.id) },
              onPlayNext: { self.playlistActions.onPlayNext(playlist.id) },
              onTap: { self.playlistActions.onTap(playlist.id) },
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
